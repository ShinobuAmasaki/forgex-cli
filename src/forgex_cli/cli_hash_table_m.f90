! Fortran Regular Expression (Forgex)
!
! MIT License
!
! (C) Amasaki Shinobu, 2023-2025
!     A regular expression engine for Fortran.
!     forgex_cli_hash_table_m module is a part of Forgex.
!
module forgex_cli_hash_table_m
   use, intrinsic :: iso_fortran_env, only: int32, int64, real64
   use :: forgex_cli_parameters_m, only: KEY_SIZE_HASH_TABLE, TABLE_SIZE_HASH_TABLE
   use :: forgex_cli_time_measurement_m, only: get_lap_time_in_appropriate_unit
   use :: forgex_cli_enum_m
   implicit none
   private

   public :: table_t

   type :: table_node_t
      character(KEY_SIZE_HASH_TABLE) :: key = ''
      character(:), allocatable :: label
      logical :: to_be_print = .false.
      integer :: node_type = 0
      character(:), allocatable :: value_c
      character(:), allocatable :: unit
      type(table_node_t), pointer :: next => null()
   end type table_node_t

   type :: table_elem_t
      type(table_node_t), pointer :: next=> null()
   end type 

   type :: table_t
      type(table_elem_t), pointer :: table(:)
      integer :: table_size
      integer :: counter = 0
   contains
      procedure :: init => initialize__cli_hash_table
      procedure :: insert_int__cli_hash_table
      procedure :: insert_real__cli_hash_table
      procedure :: insert_char__cli_hash_table
      procedure :: insert_two_int__cli_hash_table
      procedure :: insert_logical__cli_hash_table
      generic :: insert => insert_int__cli_hash_table, insert_real__cli_hash_table, &
                           insert_char__cli_hash_table, insert_two_int__cli_hash_table, insert_logical__cli_hash_table
      procedure :: find => find__cli_hash_table
      procedure :: set_to_be_printed => set_to_be_printed__cli_hash_table
      procedure :: justify => right_justify__cli_hash_table
      procedure :: write => output__cli_hash_table
      procedure :: dump => dump__cli_hash_table
   end type table_t
   
contains

   subroutine initialize__cli_hash_table(self)
      implicit none
      class(table_t), intent(inout) :: self
      allocate(self%table(TABLE_SIZE_HASH_TABLE))
      self%table_size = TABLE_SIZE_HASH_TABLE
   end subroutine initialize__cli_hash_table


   subroutine insert_logical__cli_hash_table(self, key, val, ierr)
      implicit none
      class(table_t), intent(inout) :: self
      character(*), intent(in) :: key
      logical, intent(in) :: val
      integer, intent(inout) :: ierr


      type(table_node_t), pointer :: new_node, found
      integer :: idx
      character(256) :: buf

      ierr = 0
      idx = fnv1a_hash(key, self%table_size)

      found => self%find(key)
      if (associated(found)) then
         ierr = ERR_KEY_ALREADY_EXISTS
         return
      end if

      allocate(new_node)
      if (val) then
         new_node%value_c = 'True'
      else
         new_node%value_c = 'False'
      end if
      new_node%key = trim(key)
      new_node%next => self%table(idx)%next
      self%table(idx)%next => new_node

   end subroutine insert_logical__cli_hash_table


   subroutine insert_char__cli_hash_table(self, key, val, ierr)
      implicit none
      class(table_t), intent(inout) :: self
      character(*), intent(in) :: key
      character(*), intent(in) :: val
      integer, intent(inout) :: ierr


      type(table_node_t), pointer :: new_node, found
      integer :: idx
      character(256) :: buf

      ierr = 0
      idx = fnv1a_hash(key, self%table_size)

      found => self%find(key)
      if (associated(found)) then
         ierr = ERR_KEY_ALREADY_EXISTS
         return
      end if

      allocate(new_node)
      new_node%value_c = trim(val)
      new_node%key = trim(key)
      new_node%next => self%table(idx)%next
      self%table(idx)%next => new_node

   end subroutine insert_char__cli_hash_table


   subroutine insert_int__cli_hash_table(self, key, val, ierr)
      implicit none
      class(table_t), intent(inout) :: self
      character(*), intent(in) :: key
      integer(int32), intent(in) :: val
      integer, intent(inout) :: ierr


      type(table_node_t), pointer :: new_node, found
      integer :: idx
      character(256) :: buf

      ierr = 0
      idx = fnv1a_hash(key, self%table_size)

      found => self%find(key)
      if (associated(found)) then
         ierr = ERR_KEY_ALREADY_EXISTS
         return
      end if
      allocate(new_node)

      write(buf,'(i10)') val

      new_node%value_c = trim(buf)
      new_node%key = trim(key)
      new_node%next => self%table(idx)%next
      self%table(idx)%next => new_node

   end subroutine insert_int__cli_hash_table


   subroutine insert_two_int__cli_hash_table(self, key, val1, val2, ierr)
      implicit none
      class(table_t), intent(inout) :: self
      character(*), intent(in) :: key
      integer(int32), intent(in) :: val1, val2
      integer, intent(inout) :: ierr
      
      type(table_node_t), pointer :: new_node, found
      integer :: idx
      character(256) :: buf

      ierr = 0
      idx = fnv1a_hash(key, self%table_size)

      found => self%find(key)
      if (associated(found)) then
         ierr = ERR_KEY_ALREADY_EXISTS
         return
      end if
      allocate(new_node)

      write(buf,'(i10,a,i0)') val1, ' / ', val2

      new_node%value_c = trim(buf)
      new_node%key = trim(key)
      new_node%next => self%table(idx)%next
      self%table(idx)%next => new_node

   end subroutine insert_two_int__cli_hash_table


   subroutine insert_real__cli_hash_table(self, key, val, ierr)
      implicit none
      class(table_t), intent(inout) :: self
      character(*), intent(in) :: key
      real(real64), intent(in) :: val
      integer, intent(inout) :: ierr


      type(table_node_t), pointer :: new_node, found
      integer :: idx
      character(256) :: buf

      ierr = 0
      idx = fnv1a_hash(key, self%table_size)

      found => self%find(key)
      if (associated(found)) then
         if (trim(found%key) == trim(key)) then
            ierr = ERR_KEY_ALREADY_EXISTS
            return
         end if
      end if

      allocate(new_node)
      new_node%value_c = get_lap_time_in_appropriate_unit(val)
      new_node%key = trim(key)
      new_node%next => self%table(idx)%next
      self%table(idx)%next => new_node
   end subroutine insert_real__cli_hash_table


   function find__cli_hash_table(self, key) result(found)
      implicit none
      class(table_t), intent(in) :: self
      character(*), intent(in) :: key

      integer :: idx
      type(table_node_t), pointer :: found, current

      found => null()
      idx = fnv1a_hash(key, self%table_size)

      current => self%table(idx)%next
      do while (associated(current))
         if (trim(current%key) == trim(key)) then
            found => current
            return
         end if
         current => current%next
      end do

   end function find__cli_hash_table


   subroutine right_justify__cli_hash_table(self)
      implicit none
      class(table_t), intent(inout) :: self
      
      integer :: width, i, siz, j
      logical, allocatable :: flags(:)
      type(table_node_t), pointer :: found
      width = 0
      siz = self%counter

      allocate(flags(siz))
      do i = 1, TABLE_SIZE_HASH_TABLE
         found => self%table(i)%next
         do while (associated(found))
            if (found%to_be_print) width = max(len_trim(found%key)+1, width)
            found => found%next
         end do
      end do

      do i = 1, TABLE_SIZE_HASH_TABLE
         found => self%table(i)%next
         do while (associated(found))
            if (found%to_be_print) then
               block 
                  character(width) :: buf
                  allocate(character(len=width) :: found%label)
                  buf = trim(found%key)
                  found%label = adjustr(buf)
               end block
            end if
            found => found%next
         end do
      end do

   end subroutine right_justify__cli_hash_table


   subroutine set_to_be_printed__cli_hash_table(self, key, ierr)
      implicit none
      class(table_t), intent(in) :: self
      character(*), intent(in) :: key
      integer, intent(inout) :: ierr

      type(table_node_t), pointer :: found

      found => self%find(key)

      if (.not.associated(found)) then
         ierr = ERR_NOT_FOUND
         return
      end if

      found%to_be_print = .true.
   end subroutine set_to_be_printed__cli_hash_table


   subroutine output__cli_hash_table(self, key)
      implicit none
      class(table_t), intent(in) :: self
      character(*), intent(in) :: key
      type(table_node_t), pointer :: found

      found => self%find(key)

      if (found%to_be_print) then
         write(*, '(a,1x,": ",a)') found%label, found%value_c
      end if

   end subroutine output__cli_hash_table


   subroutine dump__cli_hash_table(self, out_unit)
      use, intrinsic :: iso_fortran_env, only: stderr=>error_unit
      implicit none
      class(table_t), intent(in) :: self
      integer, intent(in), optional :: out_unit
      integer :: i, uni

      class(table_node_t), pointer :: current

      uni = stderr
      if (present(out_unit)) uni = out_unit

      do i = 1, self%table_size
         write(uni,"(a, i4, a)", advance='no') "Bucket ", i, ": "
         current => self%table(i)%next
         do while (associated(current))
            write(uni, "(a,a)", advance='no') trim(current%key), " -> "
            current => current%next
         end do
         write(uni, "(a)") "NULL"
      end do
   end subroutine dump__cli_hash_table

!====================================================================-!

   ! cf. http://www.isthe.com/chongo/tech/comp/fnv/index.html
   function fnv1a_hash(key, table_size) result(hash_value)
      implicit none
      character(*), intent(in) :: key
      integer(int32), intent(in) :: table_size
      
      integer(int64) :: hash
      integer(int64), parameter :: FNV_OFFSET_BASICS = 2166136261_int64
      integer(int64), parameter :: FNV_PRIME = 16777619_int64
      integer(int64) :: word
      integer(int32) :: i32_max = huge(0)

      integer(int32) :: i, len_key, hash_value, padding_size

      len_key = len_trim(key)
      hash = FNV_OFFSET_BASICS

      padding_size = (len_key/8 +1)*8
      block
         character(padding_size) :: fix_sized
         fix_sized = trim(key)

         do i = 1, padding_size, 8
            word = transfer(fix_sized(i:i+7), word)
            hash = ieor(hash, word) * FNV_PRIME
         end do

         hash_value =int(modulo(iand(hash, huge(0_int64)), int(table_size, kind=int64)), int32) + 1
      end block

   end function fnv1a_hash

end module forgex_cli_hash_table_m