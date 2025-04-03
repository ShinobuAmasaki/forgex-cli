! Fortran Regular Expression (Forgex)
!
! MIT License
!
! (C) Amasaki Shinobu, 2023-2025
!     A regular expression engine for Fortran.
!     forgex_cli_debug_m module is a part of Forgex.
!
module forgex_cli_debug_m
   use, intrinsic :: iso_fortran_env, only: int32,real64, stderr => error_unit, stdout => output_unit
   use :: forgex_cli_time_measurement_m, only: time_begin, time_lap, get_lap_time_in_appropriate_unit
   use :: forgex_cli_parameters_m, only: NUM_DIGIT_KEY, fmt_out_time, fmt_out_int, fmt_out_ratio, &
            fmt_out_logi, fmta, fmt_out_char, CRLF, LF, HEADER_MAIN, HEADER_DFA, HEADER_NFA ,FOOTER
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
      ! use :: forgex_cli_print_m
      use :: forgex_cli_hash_table_m
      use :: forgex_cli_keys_hash_table
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
         if (trim(middle) == '') middle = "<not implemented yet>" 
         if (trim(suffix) == '') suffix = "<none>" 

         call table%init()
         call table%insert(k_tree_count, tree%top, size(tree%nodes), ierr)
         call table%insert(k_pattern, pattern, ierr)
         call table%insert(k_parse_time, lap1, ierr)
         call table%insert(k_literal_all, entire, ierr)
         call table%insert(k_literal_pre, prefix, ierr)
         call table%insert(k_literal_mid, middle, ierr)
         call table%insert(k_literal_post, suffix, ierr)
         call table%insert(k_literal_time, lap2, ierr)

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

         if (flags(FLAG_VERBOSE)) call table%set_to_be_printed(k_tree_count, ierr)
         call table%set_to_be_printed(k_pattern, ierr)
         call table%set_to_be_printed(k_parse_time, ierr)
         call table%set_to_be_printed(k_literal_time, ierr)
         call table%set_to_be_printed(k_literal_all, ierr)
         call table%set_to_be_printed(k_literal_pre, ierr)
         call table%set_to_be_printed(k_literal_mid, ierr)
         call table%set_to_be_printed(k_literal_post, ierr)
         

         
         if (.not. flags(FLAG_NO_TABLE)) then
            write(stdout, fmta) HEADER_MAIN
            call table%justify()
            call table%write(k_pattern)
            call table%write(k_parse_time)
            call table%write(k_literal_time)
            call table%write(k_literal_all)
            call table%write(k_literal_pre)
            call table%write(k_literal_mid)
            call table%write(k_literal_post)
            call table%write(k_tree_count)
            if (flags(FLAG_VERBOSE)) then
               call table%set_to_be_printed(k_tree_count, ierr)            
            end if
         end if

         if (flags(FLAG_TABLE_ONLY)) then
            write(stdout, fmta) FOOTER
            return
         else if (flags(FLAG_NO_TABLE)) then
            write(stdout, fmta) ast
            return
         end if
         write(stdout, fmta) FOOTER
         write(stdout, fmta) ast
         write(stdout, fmta) FOOTER   
      end block output

   end subroutine do_debug_ast


   subroutine do_debug_thompson(flags, pattern)
      use :: forgex_automaton_m
      use :: forgex_syntax_tree_graph_m
      use :: forgex_utility_m
      use :: forgex_error_m
      use :: forgex_cube_m
      use :: forgex_cli_utils_m
      use :: forgex_cli_hash_table_m
      use :: forgex_cli_keys_hash_table
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

         call table%init()
         call table%insert(k_tree_count, tree%top, size(tree%nodes), ierr)
         call table%insert(k_pattern, pattern, ierr)
         call table%insert(k_parse_time, lap1, ierr)
         call table%insert(k_nfa_time, lap2, ierr)
         call table%insert(k_nfa_count, automaton%nfa%top, size(automaton%nfa%graph), ierr)
      end block output_prepare

      output: block
         call table%set_to_be_printed(k_pattern, ierr)
         call table%set_to_be_printed(k_parse_time, ierr)
         call table%set_to_be_printed(k_nfa_time, ierr)
         if ( flags(FLAG_VERBOSE)) then
            call table%set_to_be_printed(k_tree_count, ierr)
            call table%set_to_be_printed(k_nfa_count, ierr)
         end if

         if (.not. flags(FLAG_NO_TABLE)) then
            write(stdout, fmta) HEADER_MAIN
            call table%justify()
            call table%write(k_pattern)
            call table%write(k_parse_time)
            call table%write(k_nfa_time)
            call table%write(k_tree_count)
            call table%write(k_nfa_count)
         end if
         if (flags(FLAG_TABLE_ONLY)) return

         write(stdout, fmta) HEADER_NFA
         write(stdout, fmta) trim(nfa)
         write(stdout, fmta) FOOTER

      end block output
   end subroutine do_debug_thompson


end module forgex_cli_debug_m
