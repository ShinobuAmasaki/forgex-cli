! Fortran Regular Expression (Forgex)
!
! MIT License
!
! (C) Amasaki Shinobu, 2023-2024
!     A regular expression engine for Fortran.
!     forgex_cli_debug_m module is a part of Forgex.
!
module forgex_cli_debug_m
   use, intrinsic :: iso_fortran_env, only: int32,real64, stderr => error_unit, stdout => output_unit
   use :: forgex_cli_time_measurement_m, only: time_begin, time_lap, get_lap_time_in_appropriate_unit
   use :: forgex_cli_parameters_m, only: NUM_DIGIT_KEY, fmt_out_time, fmt_out_int, fmt_out_ratio, &
            fmt_out_logi, fmta, fmt_out_char, CRLF, LF, HEADER_DFA, HEADER_NFA ,FOOTER
   use :: forgex_enums_m, only: FLAG_HELP, FLAG_NO_TABLE, FLAG_VERBOSE, FLAG_TABLE_ONLY, OS_WINDOWS
   use :: forgex_cli_utils_m, only: get_os_type
   use :: forgex_cli_help_messages_m, only: print_help_debug_ast, print_help_debug_thompson
   implicit none
   private

   public :: do_debug_ast
   public :: do_debug_thompson

contains

   subroutine do_debug_ast(flags, pattern)
      use :: forgex_syntax_tree_graph_m
      use :: forgex_syntax_tree_optimize_m
      ! use :: forgex_syntax_tree_optimize_exp_m
      use :: forgex_cli_print_m
      use :: forgex_error_m
      implicit none
      logical, intent(in) :: flags(:)
      character(*), intent(in) :: pattern

      type(tree_t) :: tree
      integer :: root
      integer :: uni, ierr, siz
      character(:), allocatable :: buff
      character(:),allocatable :: ast, prefix, suffix, entire, middle
      real(real64) :: lap1, lap2
      type(table_t) :: table

      if (flags(FLAG_HELP)) call print_help_debug_ast

      time_measure_1:block
         call time_begin
         call tree%build(trim(pattern))
         lap1 = time_lap()
      end block time_measure_1

      if (.not. tree%is_valid) then
         write(stderr, '(a)') get_error_message(tree%code)
         stop
      end if

      time_measure_2: block
         call time_begin
         call extract_literal(tree, entire, prefix, suffix, middle)
         lap2 = time_lap()
      end block time_measure_2

      output_prepare: block
         
         middle = "<not implemented yet>" 
         if (trim(entire) == '') entire = "<none>" 
         if (trim(prefix) == '') prefix = "<none>" 
         ! if (trim(middle) == '') middle = "<not implemented yet>" 
         if (trim(suffix) == '') suffix = "<none>" 

         call table%init(INFO_TABLE_KEYS)
         call table%register_int(i_tree_allocated, size(tree%nodes))
         call table%register_int(i_tree_count, tree%top)
         call table%register_char(i_pattern, pattern)
         call table%register_real(i_parse_time, lap1)
         call table%register_char(i_literal_all, entire)
         call table%register_char(i_literal_pre, prefix)
         call table%register_char(i_literal_mid, middle)
         call table%register_char(i_literal_post, suffix)
         call table%register_real(i_literal_time, lap2)

         open(newunit=uni, status='scratch')
         call tree%print(uni)

         inquire(unit=uni, size=siz)
         allocate(character(siz+2) :: buff)

         rewind(uni)
         read(uni, fmta, iostat=ierr) buff
         close(uni)

         ast = trim(buff)

      end block output_prepare

      output: block

         table%info(i_pattern)%is        = .true.
         table%info(i_parse_time)%is     = .true.
         table%info(i_literal_time)%is   = .true.
         table%info(i_literal_all)%is    = .true.
         table%info(i_literal_pre)%is    = .true.
         table%info(i_literal_mid)%is    = .true.
         table%info(i_literal_post)%is   = .true.

         if (flags(FLAG_VERBOSE)) then
            table%info(i_tree_count)%is     = .true.
            table%info(i_tree_allocated)%is = .true.
         end if
         
         if (.not. flags(FLAG_NO_TABLE)) then
            call table%justify()
            call table%write()
         end if

         if (flags(FLAG_TABLE_ONLY)) return
         write(stdout, fmta) ast
   
      end block output

   end subroutine do_debug_ast


   subroutine do_debug_thompson(flags, pattern)
      use :: forgex_automaton_m
      use :: forgex_syntax_tree_graph_m
      use :: forgex_utility_m
      use :: forgex_error_m
      use :: forgex_cube_m
      use :: forgex_cli_utils_m
      use :: forgex_cli_print_m
      implicit none
      logical, intent(in) :: flags(:)
      character(*), intent(in) :: pattern

      type(tree_t) :: tree
      type(automaton_t) :: automaton
      type(table_t) :: table
      integer :: root
      integer :: uni, ierr, i
      character(:), allocatable :: nfa
      character(256) :: line
      real(real64) :: lap1, lap2, lap3


      if (flags(FLAG_HELP)) call print_help_debug_thompson
      if (pattern == '') call print_help_debug_thompson
      
      time_measure: block
         call time_begin()
         call tree%build(trim(pattern))
         lap1 = time_lap()

         if (.not. tree%is_valid) then
            write(stderr, '(a)') get_error_message(tree%code)
            stop
         end if

         call automaton%nfa%build(tree, automaton%nfa_entry, automaton%nfa_exit, automaton%cube)
         lap2 = time_lap()
      end block time_measure


      output_prepare: block
         nfa = ''
         open(newunit=uni, status='scratch')
         call automaton%nfa%print(uni, automaton%nfa_exit)

         rewind(uni)
         ierr = 0
         do while (ierr == 0)
            read(uni, fmta, iostat=ierr) line
            if (ierr /= 0) exit

            if (get_os_type() == OS_WINDOWS) then
               nfa = nfa//trim(line)//CRLF
            else
               nfa = nfa//trim(line)//LF
            end if

         end do
         close(uni)

         call table%init(INFO_TABLE_KEYS)
         call table%register_int(i_tree_allocated, size(tree%nodes))
         call table%register_int(i_tree_count, tree%top)
         call table%register_char(i_pattern, pattern)
         call table%register_real(i_parse_time, lap1)
         call table%register_real(i_nfa_time, lap2)
         call table%register_int(i_nfa_count, automaton%nfa%top)
         call table%register_int(i_nfa_allocated, size(automaton%nfa%graph))
      end block output_prepare

      output: block
         character(NUM_DIGIT_KEY) :: parse_time, nfa_time, memory, nfa_count, nfa_allocated, tree_count, tree_allocated
         character(NUM_DIGIT_KEY) :: cbuff(7) = ''
         integer :: memsiz

         table%info(i_pattern)%is        = .true.
         table%info(i_parse_time)%is     = .true.
         table%info(i_nfa_time)%is       = .true.

         if (flags(FLAG_VERBOSE)) then
            table%info(i_tree_count)%is     = .true.
            table%info(i_tree_allocated)%is = .true.
            table%info(i_nfa_count)%is      = .true.
            table%info(i_nfa_allocated)%is  = .true.
         end if

         if (.not. flags(FLAG_NO_TABLE)) then
            call table%justify()
            call table%write()
         end if

         if (flags(FLAG_TABLE_ONLY)) return
         
         write(stdout, *) ""
         write(stdout, fmta) HEADER_NFA
         write(stdout, fmta) trim(nfa)
         write(stdout, fmta) "Note: all segments of NFA were disjoined with overlapping portions."
         write(stdout, fmta) FOOTER

      end block output
   end subroutine do_debug_thompson



!=====================================================================!



end module forgex_cli_debug_m
