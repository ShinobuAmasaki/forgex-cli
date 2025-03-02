module forgex_cli_print_m
   use :: iso_fortran_env
   use :: forgex_cli_parameters_m
   implicit none
   private

   integer, parameter, public :: KEYS_NUM = 19, KEYS_MAX_LENGTH = 32

   ! 20 Keys
   character(KEYS_MAX_LENGTH), parameter, public :: k_pattern        = "pattern"
   character(KEYS_MAX_LENGTH), parameter, public :: k_text           = "text"
   character(KEYS_MAX_LENGTH), parameter, public :: k_runs_engine    = "runs engine"
   character(KEYS_MAX_LENGTH), parameter, public :: k_matching_result= "result"

   character(KEYS_MAX_LENGTH), parameter, public :: k_parse_time     = "parse time"
   character(KEYS_MAX_LENGTH), parameter, public :: k_nfa_time       = "compile nfa time"
   character(KEYS_MAX_LENGTH), parameter, public :: k_literal_time   = "extract literal time"
   character(KEYS_MAX_LENGTH), parameter, public :: k_total_time     = "total time"
   character(KEYS_MAX_LENGTH), parameter, public :: k_dfa_init_time  = "dfa initialize time"
   character(KEYS_MAX_LENGTH), parameter, public :: k_matching_time  = "search time"
   
   character(KEYS_MAX_LENGTH), parameter, public :: k_tree_count     = "tree node count"
   character(KEYS_MAX_LENGTH), parameter, public :: k_tree_allocated = "tree node allocated"
   character(KEYS_MAX_LENGTH), parameter, public :: k_nfa_count      = "nfa states"
   character(KEYS_MAX_LENGTH), parameter, public :: k_nfa_allocated  = "nfa states allocated"
   character(KEYS_MAX_LENGTH), parameter, public :: k_dfa_count      = "dfa states"
   
   character(KEYS_MAX_LENGTH), parameter, public :: k_literal_all    = "extracted literal"
   character(KEYS_MAX_LENGTH), parameter, public :: k_literal_pre    = "extracted prefix"   
   character(KEYS_MAX_LENGTH), parameter, public :: k_literal_mid    = "extracted middle"
   character(KEYS_MAX_LENGTH), parameter, public :: k_literal_post   = "extracted suffix"
   
   ! index of the key; 順番が大事
   enum, bind(c)
      enumerator :: i_null
      enumerator :: i_pattern
      enumerator :: i_text

      enumerator :: i_literal_all
      enumerator :: i_literal_pre
      enumerator :: i_literal_mid
      enumerator :: i_literal_post
      enumerator :: i_literal_time
      enumerator :: i_parse_time
      enumerator :: i_nfa_time
      enumerator :: i_dfa_init_time
      enumerator :: i_matching_time

      enumerator :: i_tree_count
      enumerator :: i_tree_allocated
      enumerator :: i_runs_engine
      enumerator :: i_nfa_count
      enumerator :: i_nfa_allocated
      enumerator :: i_dfa_count

      enumerator :: i_matching_result
      enumerator :: i_total_time
   end enum

   ! 順序が重要
   character(KEYS_MAX_LENGTH), dimension(KEYS_NUM), public, parameter :: info_table_keys = &
      [ k_pattern, &
        k_text, &
        k_literal_all, &
        k_literal_pre, &
        k_literal_mid, &
        k_literal_post, &
        k_literal_time, &
        k_parse_time, &
        k_nfa_time, &
        k_dfa_init_time, &
        k_matching_time, &
        k_tree_count, &
        k_tree_allocated, &
        k_runs_engine, &
        k_nfa_count, &
        k_nfa_allocated, &
        k_dfa_count, &
        k_matching_result,&
        k_total_time &
      ]

   type :: ac_t
      character(:), allocatable :: c
   end type ac_t

   type, public :: info_node_t
      character(KEYS_MAX_LENGTH) :: name
      character(:), allocatable  :: key
      logical :: is = .false.
      character(:), allocatable :: value
      character(:), allocatable :: unit
      integer(int32) :: raw_val_i = 0
      real(real64) :: raw_val_r = 0d0
      integer :: key_width = 0, idx = 0
   end type info_node_t

   type, public :: table_t
      type(info_node_t) :: info(KEYS_NUM)
   contains
      procedure :: init => init_info
      procedure :: justify => right_justify
      procedure :: i => get_index
      procedure :: write =>info_output
      procedure :: register_real
      procedure :: register_char
      procedure :: register_int
   end type table_t

   public :: i_pattern
   public :: i_text
   public :: i_runs_engine
   public :: i_matching_result

   public :: i_parse_time
   public :: i_nfa_time
   public :: i_literal_time
   public :: i_total_time
   public :: i_dfa_init_time
   public :: i_matching_time
   
   public :: i_tree_count
   public :: i_tree_allocated
   public :: i_nfa_count
   public :: i_nfa_allocated
   public :: i_dfa_count
   
   public :: i_literal_all
   public :: i_literal_pre
   public :: i_literal_mid
   public :: i_literal_post

contains


   subroutine init_info(self, keys)
      implicit none
      class(table_t), intent(inout) :: self
      character(KEYS_MAX_LENGTH), intent(in) :: keys(:)
      integer :: i, siz

      siz = size(keys, dim=1)

      do i =  1, siz
         self%info(i)%name = keys(i)
         self%info(i)%idx = i
         self%info(i)%key_width = len_trim(self%info(i)%name)
      end do

   end subroutine init_info


   subroutine right_justify(self)
      implicit none
      class(table_t), intent(inout) :: self

      integer :: width, i, siz
      character(:), allocatable :: label(:)
      logical, allocatable :: flags(:)

      width = 0
      siz = KEYS_NUM

      allocate(flags(siz))
      flags(:) = self%info(:)%is

      width = maxval(self%info(:)%key_width+1, mask=flags)
      allocate(character(width) :: label(siz))
      
      do i = 1, siz
         if (flags(i)) then
            label(i) = trim(adjustl(self%info(i)%name))//":"
            self%info(i)%key = adjustr(label(i))
         end if
      end do

   end subroutine right_justify


   function get_index(self, name) result(res)
      implicit none
      class(table_t), intent(in) :: self
      character(*), intent(in) :: name
      integer :: res

      integer :: i, siz

      res = 0
      siz = KEYS_NUM

      do i = 1, siz
         if (trim(name) == trim(adjustl(self%info(i)%name))) then
            res = i
            return
         end if
      end do

   end function get_index

   subroutine register_char(self, idx, text)
      implicit none
      class(table_t), intent(inout) :: self
      integer, intent(in) :: idx
      character(*), intent(in) :: text

      if (text == '') then
         self%info(idx)%value = ''
      else
         self%info(idx)%value = text
      end if

   end subroutine register_char


   subroutine register_int(self, idx, val)
      implicit none
      class(table_t), intent(inout) :: self
      integer, intent(in) :: idx, val
      character(256) :: buf

      write(buf, '(i10)') val
      self%info(idx)%value = trim(buf)

   end subroutine register_int

   
   subroutine register_real(self, idx, val)
      use :: forgex_cli_time_measurement_m
      implicit none
      class(table_t), intent(inout) :: self
      integer, intent(in) :: idx
      real(real64), intent(in) :: val
      
      self%info(idx)%value = get_lap_time_in_appropriate_unit(val)

   end subroutine register_real


   subroutine info_output(self)
      implicit none
      class(table_t),intent(in) :: self
      integer :: i, siz

      siz = KEYS_NUM

      do i = 1, siz
         if (self%info(i)%is) then
            ! if (len_trim(self%info(i)%value) < 10) then
            !    write(*,'(a, 1x, a9)') self%info(i)%key, self%info(i)%value
            ! else
            !    write(*,'(a, 1x, a)') self%info(i)%key, self%info(i)%value
            ! end if
            write(*, '(a,1x,a)') self%info(i)%key, self%info(i)%value
         end if
      end do
   end subroutine info_output

end module forgex_cli_print_m