module forgex_cli_print_m
   use :: iso_fortran_env
   implicit none
   private

   integer, parameter, public :: KEYS_NUM = 20, KEYS_MAX_LENGTH = 32

   ! 20 Keys
   character(KEYS_MAX_LENGTH), parameter :: pattern_key    = "pattern"
   character(KEYS_MAX_LENGTH), parameter :: text_key       = "text"
   character(KEYS_MAX_LENGTH), parameter :: runs_engine_key= "runs engine"
   character(KEYS_MAX_LENGTH), parameter :: matching_result= "result"
   character(KEYS_MAX_LENGTH), parameter :: memory         = "memory (estimated)"

   character(KEYS_MAX_LENGTH), parameter :: parse_time     = "parse time"
   character(KEYS_MAX_LENGTH), parameter :: nfa_time       = "compile nfa time"
   character(KEYS_MAX_LENGTH), parameter :: literal_time   = "extract time"
   character(KEYS_MAX_LENGTH), parameter :: total_time     = "total time"
   character(KEYS_MAX_LENGTH), parameter :: dfa_init_time  = "dfa initialize time"
   character(KEYS_MAX_LENGTH), parameter :: matching_time  = "search time"
   
   character(KEYS_MAX_LENGTH), parameter :: tree_count     = "tree node count"
   character(KEYS_MAX_LENGTH), parameter :: tree_allocated = "tree node allocated"
   character(KEYS_MAX_LENGTH), parameter :: nfa_count      = "nfa states"
   character(KEYS_MAX_LENGTH), parameter :: nfa_allocated  = "nfa states allocated"
   character(KEYS_MAX_LENGTH), parameter :: dfa_count      = "dfa states"
   
   character(KEYS_MAX_LENGTH), parameter :: literal_all    = "extracted literal"
   character(KEYS_MAX_LENGTH), parameter :: literal_pre    = "extracted prefix"   
   character(KEYS_MAX_LENGTH), parameter :: literal_mid    = "extracted middle"
   character(KEYS_MAX_LENGTH), parameter :: literal_post   = "extracted suffix"
   
   ! 
   character(KEYS_MAX_LENGTH), dimension(KEYS_NUM), public :: keys = &
       [pattern_key, &
        text_key, &
        tree_count, &
        tree_allocated, &
        parse_time, &
        literal_all, &
        literal_pre, &
        literal_mid, &
        literal_post, &
        literal_time, & 
        runs_engine_key, &
        nfa_time, &
        nfa_count, &
        nfa_allocated, &
        dfa_count, &
        dfa_init_time, &
        matching_result,&
        matching_time, &
        total_time, &
        memory &
       ]

   type :: ac_t
      character(:), allocatable :: c
   end type ac_t

   type, public :: info_t
      character(KEYS_MAX_LENGTH) :: name
      character(:), allocatable  :: key_justified
      logical :: is_flagged = .false.
      type(ac_t) :: value
      type(ac_t) :: unit
      integer(int32) :: raw_val_i = 0
      real(real64) :: raw_val_r = 0d0
      integer :: key_width = 0, idx = 0
   contains
      procedure :: init => init_info
   end type info_t

   public :: right_justify
   public :: get_index

contains


   impure elemental subroutine init_info(self, key, i)
      implicit none
      class(info_t), intent(inout) :: self
      character(KEYS_MAX_LENGTH), intent(in) :: key
      integer, intent(in) :: i

      self%name = key
      self%idx = i
      self%key_width = len_trim(self%name)

   end subroutine init_info


   subroutine right_justify(array)
      implicit none
      type(info_t), intent(inout) :: array(:)

      integer :: width, i, siz
      character(:), allocatable :: label(:)
      logical, allocatable :: flags(:)

      width = 0
      siz = size(array, dim=1)
      allocate(flags(siz))
      flags(:) = array(:)%is_flagged

      width = maxval(array(:)%key_width+1, mask=flags)
      allocate(character(width) :: label(siz))

      
      do i = 1, siz
         if (flags(i)) then
            label(i) = trim(adjustl(array(i)%name))//":"
            array(i)%key_justified = adjustr(label(i))
         end if
      end do

   end subroutine right_justify


   function get_index(array, name) result(res)
      implicit none
      type(info_t), intent(in) :: array(:)
      character(*), intent(in) :: name
      integer :: res

      integer :: i, siz

      res = 0
      siz = size(array, dim=1)
      do i = 1, siz
         if (trim(name) == trim(adjustl(array(i)%name))) then
            res = i
            return
         end if
      end do

   end function get_index

end module forgex_cli_print_m