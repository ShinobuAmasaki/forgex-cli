module forgex_cli_print_m
   implicit none
   private

   integer, parameter :: KEYS_MAX = 21, KEYS_MAX_LENGTH = 21

   ! Keys
   character(*), parameter :: parse_time     = "parse time"
   character(*), parameter :: nfa_time       = "compile nfa time"
   character(*), parameter :: memory         = "memory (estimated)"
   character(*), parameter :: nfa_count      = "nfa states"
   character(*), parameter :: nfa_allocated  = "nfa states allocated"
   character(*), parameter :: tree_count     = "tree node count"
   character(*), parameter :: tree_allocated = "tree node allocated"

   character(*), parameter :: literal_time   = "extract time"
   character(*), parameter :: literal_all    = "extracted literal"
   character(*), parameter :: literal_pre    = "extracted prefix"
   character(*), parameter :: literal_mid    = "extracted middle"
   character(*), parameter :: literal_post   = "extracted suffix"

   character(*), parameter :: pattern_key    = "pattern"
   character(*), parameter :: text_key       = "text"
   character(*), parameter :: total_time     = "time"
   character(*), parameter :: matching_result= "result"

   character(*), parameter :: extract_time   = "extract literal time"
   character(*), parameter :: runs_engine_key= "runs engine"

   character(*), parameter :: dfa_init_time  = "dfa initialize time"
   character(*), parameter :: matching_time  = "search time"

   character(*), parameter :: dfa_count      = "dfa states"
   
   type, public :: print_keys_t
      character(len(parse_time))       :: parse_time        = parse_time
      character(len(tree_count))       :: tree_count        = tree_count
      character(len(tree_allocated))   :: tree_allocated    = tree_allocated
      character(len(literal_time))     :: literal_time      = literal_time
      character(len(literal_all))      :: literal_all       = literal_time
      character(len(literal_pre))      :: literal_pre       = literal_pre
      character(len(literal_mid))      :: literal_mid       = literal_mid
      character(len(literal_post))     :: literal_post      = literal_post
      character(len(extract_time))     :: extract_time      = extract_time
      character(len(runs_engine_key))  :: runs_engine_key   = runs_engine_key
      character(len(nfa_time))         :: nfa_time          = nfa_time
      character(len(nfa_count))        :: nfa_count         = nfa_count
      character(len(nfa_allocated))    :: nfa_allocated     = nfa_allocated
      character(len(dfa_init_time))    :: dfa_init_time     = dfa_init_time
      character(len(matching_time))    :: matching_time     = matching_time
      character(len(matching_result))  :: matching_result   = matching_result
      character(len(pattern_key))      :: pattern_key       = pattern_key
      character(len(text_key))         :: text_key          = text_key
      character(len(total_time))       :: total_time        = total_time
      integer :: count = 0, width = 0
   end type
   
   type, public :: print_flag_t
      ! Parse
      logical :: flag_parse_time       = .false.
      logical :: flag_tree_count       = .false.
      logical :: flag_tree_allocated   = .false.
      ! Literal Search
      logical :: flag_literal_time     = .false.
      logical :: flag_literal_all      = .false.
      logical :: flag_literal_pre      = .false.
      logical :: flag_literal_mid      = .false.
      logical :: flag_literal_post     = .false.
      logical :: flag_extract_time     = .false.
      ! NFA
      logical :: flag_runs_engine      = .false.
      logical :: flag_nfa_time         = .false.
      logical :: flag_nfa_count        = .false.
      logical :: flag_nfa_allocated    = .false.
      ! DFA
      logical :: flag_dfa_init_time    = .false.
      logical :: flag_matching_time    = .false.
      ! Result
      logical :: flag_matching_result  = .false.
      logical :: flag_pattern_key      = .false.
      logical :: flag_text_key         = .false.
      logical :: flag_total_time       = .false.
   end type print_flag_t

   public :: right_justify

contains

   subroutine right_justify(keys, flags, res)
      implicit none
      type(print_keys_t), intent(inout) :: keys
      type(print_flag_t), intent(in) :: flags
      character(:), allocatable, dimension(:), intent(inout) :: res

      character(:), allocatable, dimension(:) :: buff
      integer :: i
      
      i = 0
      allocate(character(KEYS_MAX_LENGTH) :: buff(KEYS_MAX))

      if (flags%flag_parse_time)       call max_width_and_count_inclement(keys%parse_time, keys%width, buff, i)
      if (flags%flag_tree_count)       call max_width_and_count_inclement(keys%tree_count, keys%width, buff, i)
      if (flags%flag_tree_allocated)   call max_width_and_count_inclement(keys%tree_allocated, keys%width, buff, i)
      if (flags%flag_literal_time)     call max_width_and_count_inclement(keys%literal_time, keys%width, buff, i)
      if (flags%flag_literal_all)      call max_width_and_count_inclement(keys%literal_all, keys%width, buff, i)
      
      if (flags%flag_literal_pre)      call max_width_and_count_inclement(keys%literal_pre, keys%width, buff, i)
      if (flags%flag_literal_mid)      call max_width_and_count_inclement(keys%literal_mid, keys%width, buff, i)
      if (flags%flag_literal_post)     call max_width_and_count_inclement(keys%literal_post, keys%width, buff, i)
      if (flags%flag_extract_time)     call max_width_and_count_inclement(keys%extract_time, keys%width, buff, i)
      if (flags%flag_runs_engine)      call max_width_and_count_inclement(keys%runs_engine_key, keys%width, buff, i)
      
      if (flags%flag_nfa_time)         call max_width_and_count_inclement(keys%nfa_time, keys%width, buff, i)
      if (flags%flag_nfa_count)        call max_width_and_count_inclement(keys%nfa_count, keys%width, buff, i)
      if (flags%flag_nfa_allocated)    call max_width_and_count_inclement(keys%nfa_allocated, keys%width, buff, i)
      if (flags%flag_dfa_init_time)    call max_width_and_count_inclement(keys%dfa_init_time, keys%width, buff, i)
      if (flags%flag_matching_time)    call max_width_and_count_inclement(keys%matching_time, keys%width, buff, i)
      
      if (flags%flag_matching_result)  call max_width_and_count_inclement(keys%matching_result, keys%width, buff, i)
      if (flags%flag_pattern_key)      call max_width_and_count_inclement(keys%pattern_key, keys%width, buff, i)
      if (flags%flag_text_key)         call max_width_and_count_inclement(keys%text_key, keys%width, buff, i)
      if (flags%flag_total_time)       call max_width_and_count_inclement(keys%total_time, keys%width, buff, i)

      keys%count = i
      allocate(character(keys%width+1) :: res(keys%count))

      do i = 1, keys%count
         res(i) = adjustr(buff(i))//":"
      end do


   end subroutine right_justify


   subroutine max_width_and_count_inclement (text, width, buff, count)
      implicit none
      character(*), intent(in) :: text
      integer, intent(inout) :: width, count
      character(*), intent(inout), dimension(:) :: buff(:)

      count = count + 1
      width = max(width, len(text)+1)
      buff(count) = adjustl(text)
   end subroutine

end module forgex_cli_print_m