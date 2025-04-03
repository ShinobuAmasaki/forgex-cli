! Fortran Regular Expression (Forgex)
!
! MIT License
!
! (C) Amasaki Shinobu, 2023-2025
!     A regular expression engine for Fortran.
!     forgex_cli_find_m module is a part of Forgex.
!
module forgex_cli_find_m
   use, intrinsic :: iso_fortran_env, stdout => output_unit
   use :: forgex_cli_parameters_m
   use :: forgex_enums_m
   use :: forgex_cli_time_measurement_m
   use :: forgex_cli_help_messages_m
   use :: forgex_cli_utils_m, only: right_justify
   implicit none
   private

   public :: do_find_match_forgex
   public :: do_find_match_lazy_dfa
   public :: do_find_match_dense_dfa

contains

   subroutine do_find_match_forgex(flags, pattern, text, is_exactly)
      use :: forgex, only: regex, operator(.in.), operator(.match.), regex_f
      use :: forgex_parameters_m, only: INVALID_CHAR_INDEX
      use :: forgex_cli_time_measurement_m
      use :: forgex_cli_utils_m, only: text_highlight_green
      ! use :: forgex_cli_print_m
      use :: forgex_cli_hash_table_m
      use :: forgex_cli_keys_hash_table
      implicit none
      logical, intent(in) :: flags(:)
      character(*), intent(in) :: pattern, text
      logical, intent(in) :: is_exactly

      real(real64) :: lap
      logical :: res
      character(:), allocatable :: res_string
      integer :: from, to, unused, ierr
      type(table_t) :: table

      res_string = ''
      from = INVALID_CHAR_INDEX
      to = INVALID_CHAR_INDEX

      call time_begin()
      if (is_exactly) then
         res = pattern .match. text
      else
         res = pattern .in. text
      end if
      lap = time_lap()

      ! Invoke regex subroutine to highlight matched substring.
      call regex(pattern, text, res_string, unused, from=from, to=to)

      output_prepare: block
         call table%init()
         call table%insert(k_pattern, pattern, ierr)
         call table%insert(k_text, '"'//text_highlight_green(text, from, to)//'"', ierr)
         call table%insert(k_matching_result, res, ierr)
         call table%insert(k_total_time, lap, ierr)
      end block output_prepare

      output: block

         if (.not. flags(FLAG_NO_TABLE)) then
            call table%set_to_be_printed(k_pattern, ierr)
            call table%set_to_be_printed(k_text, ierr)
            call table%set_to_be_printed(k_total_time, ierr)
         end if

         call table%set_to_be_printed(k_matching_result, ierr)

         call table%justify()
         call table%write(k_pattern)
         call table%write(k_text)
         call table%write(k_total_time)
         call table%write(k_matching_result)

      end block output

   end subroutine do_find_match_forgex


   subroutine do_find_match_lazy_dfa(flags, pattern, text, is_exactly)
      use :: forgex_automaton_m
      use :: forgex_syntax_tree_graph_m
      use :: forgex_syntax_tree_optimize_m
      use :: forgex_api_internal_m
      use :: forgex_nfa_state_set_m
      use :: forgex_cli_utils_m
      use :: forgex_utility_m, only: is_there_caret_at_the_top, is_there_dollar_at_the_end
      use :: forgex_parameters_m, only: ACCEPTED_EMPTY
      use :: forgex_cli_hash_table_m, only: table_t
      use :: forgex_cli_keys_hash_table
      implicit none
      logical, intent(in) :: flags(:)
      character(*), intent(in) :: pattern
      character(*), intent(in) :: text
      logical, intent(in) :: is_exactly

      type(tree_t) :: tree
      type(automaton_t) :: automaton
      type(table_t) :: table

      integer :: uni, ierr, i
      character(:), allocatable :: dfa_for_print, prefix, suffix, entire, factor_unused
      character(256) :: line
      real(real64) :: lap1, lap2, lap3, lap4, lap5
      logical :: res, flag_runs_engine, flag_fixed_string
      integer :: from, to

      dfa_for_print = ''
      lap1 = 0d0
      lap2 = 0d0
      lap3 = 0d0
      lap4 = 0d0
      lap5 = 0d0
      from = 0
      to = 0
      prefix = ''
      suffix = ''
      entire = ''
      flag_fixed_string = .false.
      flag_runs_engine = .false.
      res = .false.

      if (flags(FLAG_HELP) .or. pattern == '') call print_help_find_match_lazy_dfa

      call time_begin()
      call tree%build(trim(pattern))
      lap1 = time_lap()

      if (.not. flags(FLAG_NO_LITERAL)) then
         call extract_literal(tree, entire, prefix, suffix, factor_unused)
         if (entire /= '') flag_fixed_string = .true.
      end if
      lap2 = time_lap()

      if (.not. flag_fixed_string) then
         call automaton%preprocess(tree)
         lap3 = time_lap()

         call automaton%init()
         lap4 = time_lap()
      end if

      if (is_exactly) then

         call time_begin()
         if (flag_fixed_string) then
            if (len(text) == len(entire)) then
               res = text == entire
            end if
         else
            call runner_do_matching_exactly(automaton, text, res, prefix, suffix, flags(FLAG_NO_LITERAL), flag_runs_engine)
         end if
         lap5 = time_lap()

         if (res) then
            from = 1
            to = len(text)
         end if
      else
         block
            call time_begin()
            if (flag_fixed_string) then
               from = index(text, entire)
               if (from > 0 ) to = from + len(entire) -1
            else
               call runner_do_matching_including(automaton, text, from, to, &
                     prefix, suffix, flags(FLAG_NO_LITERAL), flag_runs_engine)
            end if

            if (from > 0 .and. to > 0) then
               res = .true.
            else if (from == ACCEPTED_EMPTY .and. to == ACCEPTED_EMPTY) then
               res = .true.
            else
               res = .false.
            end if

            lap5 = time_lap()

         end block
      end if

      open(newunit=uni, status='scratch')
      write(uni, fmta) HEADER_NFA
      call automaton%nfa%print(uni, automaton%nfa_exit)
      write(uni, fmta) HEADER_DFA
      call automaton%print_dfa(uni)

      rewind(uni)
      ierr = 0
      do while (ierr == 0)
         read(uni, fmta, iostat=ierr) line
         if (ierr/=0) exit
         if (get_os_type() == OS_WINDOWS) then
            dfa_for_print = dfa_for_print//trim(line)//CRLF
         else
            dfa_for_print = dfa_for_print//trim(line)//LF
         end if
      end do
      close(uni)

      output: block
         
         call table%init()
         call table%insert(k_pattern, trim(adjustl(pattern)), ierr)
         call table%insert(k_text, '"'//text_highlight_green(text, from, to)//'"', ierr)
         call table%insert(k_parse_time, get_lap_time_in_appropriate_unit(lap1), ierr)
         call table%insert(k_literal_time, get_lap_time_in_appropriate_unit(lap2), ierr)
         call table%insert(k_runs_engine, flag_runs_engine, ierr)
         if (flag_runs_engine) then
            call table%insert(k_nfa_time, get_lap_time_in_appropriate_unit(lap3), ierr)
            call table%insert(k_dfa_init_time, get_lap_time_in_appropriate_unit(lap4), ierr)
         else
            call table%insert(k_nfa_time, not_running, ierr)
            call table%insert(k_dfa_init_time, not_running, ierr)
         end if

         call table%insert(k_matching_time, get_lap_time_in_appropriate_unit(lap5), ierr)
         call table%insert(k_matching_result, res, ierr)
         call table%insert(k_tree_count, tree%top, size(tree%nodes, dim=1), ierr)
         call table%insert(k_nfa_count, automaton%nfa%top, automaton%nfa%nfa_limit, ierr)
         call table%insert(k_dfa_count, automaton%dfa%dfa_top, automaton%dfa%dfa_limit, ierr)

         if (flags(FLAG_NO_TABLE)) then
            continue
         else
            call table%set_to_be_printed(k_pattern, ierr)
            call table%set_to_be_printed(k_text, ierr)
            call table%set_to_be_printed(k_parse_time, ierr)
            call table%set_to_be_printed(k_literal_time, ierr)
            call table%set_to_be_printed(k_runs_engine, ierr)
            call table%set_to_be_printed(k_nfa_time, ierr)
            call table%set_to_be_printed(k_dfa_init_time, ierr)
            call table%set_to_be_printed(k_matching_time, ierr)
            call table%set_to_be_printed(k_matching_result, ierr)
            if (flags(FLAG_VERBOSE)) then
               call table%set_to_be_printed(k_tree_count, ierr)
               call table%set_to_be_printed(k_nfa_count, ierr)
               call table%set_to_be_printed(k_dfa_count, ierr)
            end if
         end if

         write(stdout, fmta) HEADER_MAIN
         call table%justify()
         call table%write(k_pattern)
         call table%write(k_text)
         call table%write(k_parse_time)
         call table%write(k_literal_time)
         call table%write(k_runs_engine)
         call table%write(k_nfa_time)
         call table%write(k_dfa_init_time)
         call table%write(k_matching_time)
         call table%write(k_matching_result)
         call table%write(k_tree_count)
         call table%write(k_nfa_count)
         call table%write(k_dfa_count)

         if (flags(FLAG_TABLE_ONLY) .or. .not. flag_runs_engine .or. flag_fixed_string) then
            write(stdout, fmta) FOOTER
            return
         end if


         write(stdout, fmta, advance='no') trim(dfa_for_print)
         write(stdout, fmta) FOOTER

      end block output

   end subroutine do_find_match_lazy_dfa


   subroutine do_find_match_dense_dfa(flags, pattern, text, is_exactly)
      use :: forgex_automaton_m
      use :: forgex_syntax_tree_graph_m
      use :: forgex_cli_time_measurement_m
      use :: forgex_dense_dfa_m
      use :: forgex_nfa_state_set_m
      use :: forgex_cli_utils_m
      use :: forgex_utility_m
      use :: forgex_cli_hash_table_m, only: table_t
      use :: forgex_cli_keys_hash_table
      implicit none
      logical, intent(in) :: flags(:)
      character(*), intent(in) :: pattern
      character(*), intent(in) :: text
      logical, intent(in) :: is_exactly

      type(tree_t) :: tree
      type(automaton_t) :: automaton
      type(table_t) :: table

      integer :: uni, ierr, i
      character(:), allocatable :: dfa_for_print
      character(256) :: line
      real(real64) :: lap1, lap2, lap3, lap4, lap5
      logical :: res
      integer :: from, to
      from = 0
      to = 0

      if (flags(FLAG_HELP) .or. pattern == '') call print_help_find_match_dense_dfa
      if (flags(FLAG_NO_LITERAL)) call info("No literal search optimization is implemented in dense DFA.")
      call time_begin()
      ! call build_syntax_tree(trim(pattern), tape, tree, root)
      call tree%build(trim(pattern))
      lap1 = time_lap()

      call automaton%preprocess(tree)
      lap2 = time_lap() ! build nfa

      call automaton%init()
      lap3 = time_lap() ! automaton initialize

      call construct_dense_dfa(automaton, automaton%initial_index)
      lap4 = time_lap() ! compile nfa to dfa

      if (is_exactly) then
         res = match_dense_dfa_exactly(automaton, text)
         if (res) then
            from = 1
            to = len(text)
         end if
      else
         block
            call match_dense_dfa_including(automaton, char(10)//text//char(10), from, to)
            if (is_there_caret_at_the_top(pattern)) then
               from = from
            else
               from = from -1
            end if

            if (is_there_dollar_at_the_end(pattern)) then
               to = to -2
            else
               to = to -1
            end if

            if (from>0 .and. to>0) then
               res = .true.
            else
               res = .false.
            end if
         end block
      end if
      lap5 = time_lap() ! search time

      open(newunit=uni, status='scratch')
      write(uni, fmta) HEADER_NFA
      call automaton%nfa%print(uni, automaton%nfa_exit)
      write(uni, fmta) HEADER_DFA
      call automaton%print_dfa(uni)

      rewind(uni)
      ierr = 0
      dfa_for_print = ''
      do while (ierr == 0)
         read(uni, fmta, iostat=ierr) line
         if (ierr/=0) exit
         if (get_os_type() == OS_WINDOWS) then
            dfa_for_print = dfa_for_print//trim(line)//CRLF
         else
            dfa_for_print = dfa_for_print//trim(line)//LF
         end if
      end do
      close(uni)

      output: block
         call table%init()
         call table%insert(k_pattern, trim(adjustl(pattern)), ierr)
         call table%insert(k_text, "'"//text_highlight_green(text, from, to)//"'", ierr)
         call table%insert(k_parse_time, get_lap_time_in_appropriate_unit(lap1), ierr)
         call table%insert(k_nfa_time, get_lap_time_in_appropriate_unit(lap2), ierr)
         call table%insert(k_dfa_init_time, get_lap_time_in_appropriate_unit(lap3), ierr)
         call table%insert(k_dfa_compile_time, get_lap_time_in_appropriate_unit(lap4), ierr)
         call table%insert(k_matching_time, get_lap_time_in_appropriate_unit(lap5), ierr)
         call table%insert(k_matching_result, res, ierr)
         call table%insert(k_tree_count, tree%top, size(tree%nodes, dim=1), ierr)
         call table%insert(k_nfa_count, automaton%nfa%top, automaton%nfa%nfa_limit, ierr)
         call table%insert(k_dfa_count, automaton%dfa%dfa_top, automaton%dfa%dfa_limit, ierr)

         if (flags(FLAG_NO_TABLE)) then
            continue
         else
            call table%set_to_be_printed(k_pattern, ierr)
            call table%set_to_be_printed(k_text, ierr)
            call table%set_to_be_printed(k_parse_time, ierr)
            call table%set_to_be_printed(k_nfa_time, ierr)
            call table%set_to_be_printed(k_dfa_init_time, ierr)
            call table%set_to_be_printed(k_dfa_compile_time, ierr)
            call table%set_to_be_printed(k_matching_time, ierr)
            call table%set_to_be_printed(k_matching_result, ierr)
            if (flags(FLAG_VERBOSE)) then
               call table%set_to_be_printed(k_tree_count, ierr)
               call table%set_to_be_printed(k_nfa_count, ierr)
               call table%set_to_be_printed(k_dfa_count, ierr)
            end if
         end if

         write(stdout, fmta) HEADER_MAIN
         call table%justify()
         call table%write(k_pattern)
         call table%write(k_text)
         call table%write(k_parse_time)
         call table%write(k_nfa_time)
         call table%write(k_dfa_compile_time)
         call table%write(k_matching_time)
         call table%write(k_matching_result)
         call table%write(k_tree_count)
         call table%write(k_nfa_count)
         call table%write(k_dfa_count)

         if (flags(FLAG_TABLE_ONLY))  then
            write(stdout, fmta) FOOTER
            return
         end if

         write(stdout, *) ""
         write(stdout, fmta, advance='no') trim(dfa_for_print)
         write(stdout, fmta) FOOTER
      end block output


   end subroutine do_find_match_dense_dfa

   subroutine runner_do_matching_exactly(automaton, text, res, prefix, suffix, flag_no_literal_optimize, runs_engine)
      use :: forgex_automaton_m
      use :: forgex_syntax_tree_optimize_m
      use :: forgex_cli_api_internal_no_opts_m
      use :: forgex_api_internal_m
      implicit none
      type(automaton_t), intent(inout) :: automaton
      character(*), intent(in) :: text
      logical, intent(inout) :: res
      logical, intent(inout) :: runs_engine
      logical, intent(in) :: flag_no_literal_optimize
      character(*), intent(in) :: prefix, suffix



      if (flag_no_literal_optimize) then
         call do_matching_exactly_no_literal_opts(automaton, text, res)
         runs_engine = .true.
      else
         call do_matching_exactly(automaton, text, res, prefix, suffix, runs_engine)
      end if

   end subroutine runner_do_matching_exactly


   subroutine runner_do_matching_including(automaton, text, from, to, prefix, suffix, flag_no_literal_optimize, runs_engine)
      use :: forgex_syntax_tree_optimize_m
      use :: forgex_automaton_m
      use :: forgex_api_internal_m
      use :: forgex_cli_api_internal_no_opts_m
      implicit none
      type(automaton_t), intent(inout) :: automaton
      character(*), intent(in) :: text
      integer(int32), intent(inout) :: from, to
      character(*), intent(in) :: prefix, suffix
      logical,intent(in) :: flag_no_literal_optimize
      logical, intent(inout) :: runs_engine

      if (flag_no_literal_optimize) then
         call do_matching_including_no_literal_opts(automaton, text, from, to)
         runs_engine = .true.
      else
         call do_matching_including(automaton, text, from, to, prefix, suffix, runs_engine)
      end if
   end subroutine runner_do_matching_including


end module forgex_cli_find_m