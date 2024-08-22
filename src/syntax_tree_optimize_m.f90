
#ifdef IMPURE
#define pure
#endif
module forgex_syntax_tree_optimize_m
   use, intrinsic :: iso_fortran_env, only: int32
   use :: forgex_syntax_tree_node_m, only: tree_node_t
   use :: forgex_syntax_tree_graph_m, only: tree_t
   use :: forgex_utf8_m
   use :: forgex_enums_m
   implicit none
   private

   public :: get_prefix_literal
   public :: get_postfix_literal
   public :: get_entire_literal

contains

   pure function get_prefix_literal(tree) result(chara)
      implicit none
      type(tree_t), intent(in) :: tree
      character(:), allocatable :: chara
      logical :: each_res

      chara = ''

      call get_prefix_literal_internal(tree%nodes, tree%top, chara, each_res)

   end function get_prefix_literal

   
   pure function get_postfix_literal(tree) result(chara)
      implicit none
      type(tree_t), intent(in) :: tree
      character(:), allocatable :: chara
      logical :: each_res, or_exists

      chara = ''
      or_exists = .false.
      call get_postfix_literal_internal(tree%nodes, tree%top, chara, each_res, or_exists)

   end function get_postfix_literal


   pure function get_entire_literal(tree) result(chara)
      implicit none
      type(tree_t), intent(in) :: tree 
      character(:),allocatable :: chara
      logical :: each_res
      chara = ''

      call get_entire_literal_internal(tree%nodes, tree%top, chara, each_res)
   end function get_entire_literal

 
   pure function is_literal_tree_node(node) result(res)
      implicit none
      type(tree_node_t), intent(in) :: node
      logical :: res

      res = .false.
      if (node%op == op_char .and. size(node%c) == 1) then
         if (node%c(1)%min == node%c(1)%max) then
            res = .true.
         end if
      end if
   end function is_literal_tree_node


   pure function is_char_class_tree_node(node) result(res)
      implicit none
      type(tree_node_t), intent(in) :: node
      logical :: res

      res = .false.
      if (node%op == op_char) res = .true.

   end function is_char_class_tree_node


   pure recursive subroutine get_entire_literal_internal(tree, idx, literal, res)
      use :: forgex_syntax_tree_node_m
      implicit none
      type(tree_node_t), intent(in) :: tree(:)
      integer(int32), intent(in) :: idx
      character(:), allocatable, intent(inout) :: literal
      logical, intent(inout) :: res

      type(tree_node_t) :: node
      integer :: i
      node = tree(idx)

      if (node%op == op_concat) then
         call get_entire_literal_internal(tree, node%left_i, literal, res)
         if (literal == '') return
         if (res) then
            call get_entire_literal_internal(tree, node%right_i, literal, res)
         else
            literal = ''
         end if
         if (literal == '') return

      else if (node%op == op_repeat) then
         if (node%max_repeat == node%min_repeat) then
            do i = 1, node%min_repeat
               call get_entire_literal_internal(tree, node%left_i, literal, res)
            end do
         else
            res = .false.
            literal = ''
         end if

      else if (is_literal_tree_node(node)) then
         if (size(node%c, dim=1) == 1) then
            if (node%c(1)%min == node%c(1)%max) then
               literal = literal//char_utf8(node%c(1)%min)
               res = .true.
               return
            end if
         end if
         res = .false.
         literal = ''

      else
         res = .false.
         literal = ''

      end if

   end subroutine get_entire_literal_internal
   

   pure recursive subroutine get_prefix_literal_internal(tree, idx, prefix, res)
      use :: forgex_parameters_m
      implicit none
      type(tree_node_t), intent(in) :: tree(:)
      integer(int32), intent(in) :: idx
      character(:), allocatable, intent(inout) :: prefix
      logical, intent(inout) :: res

      logical :: res_left, res_right, unused
      type(tree_node_t) :: node
      character(:), allocatable :: candidate1, candidate2
      integer :: j, n
      
      if (idx < 1) return
      node = tree(idx)
      res_left = .false.
      res_right = .false.
      candidate1 = ''
      candidate2 = ''

      select case (node%op)
      case (op_concat)
         call get_prefix_literal_internal(tree, node%left_i, candidate1, res_left)

         if (res_left) then
            call get_prefix_literal_internal(tree, node%right_i, candidate2, res_right)
         end if

         prefix = prefix//candidate1//candidate2

         res = res_left .and. res_right

      case(op_union)
         call get_prefix_literal_internal(tree, node%left_i, candidate1, unused)
         call get_prefix_literal_internal(tree, node%right_i, candidate2, unused)
         prefix = extract_same_part_prefix(candidate1, candidate2)
         res = .false.
      case(op_repeat)
         n = node%min_repeat
         do j = 1, n
            call get_prefix_literal_internal(tree, node%left_i, prefix, res_left)
         end do
         res = res_left
      case (op_char)
         if (is_literal_tree_node(node)) then
            if (node%c(1)%min == node%c(1)%max) then
               prefix = prefix//adjustl_multi_byte(char_utf8(node%c(1)%min))
               res = .true.
               return
            end if
         end if
         res = .false.
      case default
         res = .false.
      end select
   end subroutine get_prefix_literal_internal


   pure recursive subroutine get_postfix_literal_internal(tree, idx, postfix, res, or_exists)
      implicit none
      type(tree_node_t), intent(in) :: tree(:)
      integer(int32), intent(in) :: idx
      character(:), allocatable, intent(inout) :: postfix
      logical, intent(inout) :: res, or_exists
      
      logical :: res_left, res_right, unused, or_r, or_l
      type(tree_node_t) :: node
      character(:), allocatable :: candidate1, candidate2
      integer :: n, j

      if (idx < 1) return
      node = tree(idx)
      res_left = .false.
      res_right = .false.
      candidate1 = ''
      candidate2 = ''
      or_l = .false.
      or_r = .false.


      if (idx < 1) return

      select case (node%op)
      case (op_concat)
         call get_postfix_literal_internal(tree, node%right_i, postfix, res_right, or_r)

         if (res_right) then
            call get_postfix_literal_internal(tree, node%left_i, candidate1, res_left, or_l)
         end if

         or_exists = or_l .or. or_r
         if (or_r .and. or_l) then
            res = .false.
            return
         else if (or_r) then
            res = .false.
            return
         else
            postfix = candidate1//postfix
            res = .true.
            return
         end if
   
      case (op_union) !OR
         call get_postfix_literal_internal(tree, node%left_i, candidate1, res_left, or_l)
         call get_postfix_literal_internal(tree, node%right_i, candidate2, res_right, or_r)

         postfix = extract_same_part_postfix(candidate1, candidate2)

         res = postfix /= ""
         or_exists = .true.

      case(op_repeat)
         n = node%min_repeat
         do j = 1, n
            call get_postfix_literal_internal(tree, node%left_i, postfix, res_right, or_r)

         end do
         res = postfix /= ''
         or_exists = or_r

      case(op_closure)
         or_exists = .false.
         ! +に対する処理
         if (node%parent_i /= 0) then
            if(tree(node%parent_i)%op == op_concat) then
               ! 親の演算子が連結の場合、
               
               ! 姉ノードのリテラルを抽出し、子ノードのリテラルがそれと一致する場合は真を返す
               if (tree(node%parent_i)%right_i == node%own_i) then
                  call get_postfix_literal_internal(tree, tree(node%parent_i)%left_i, candidate1, res_left, or_l)


                  call get_postfix_literal_internal(tree, node%left_i, candidate2, res_left, or_l)
                  if (candidate1 == candidate2) then
                     postfix = ''
                     res = .true.
                     return
                  endif
               else if (tree(node%parent_i)%left_i == node%own_i) then
                  call get_postfix_literal_internal(tree, tree(node%parent_i)%right_i, candidate1, res_right, or_r)
                  call get_postfix_literal_internal(tree, node%right_i, candidate2, res_right, or_r)
                  if (candidate1 == candidate2) then
                     postfix = ''
                     res = .true.
                     return
                  end if
               end if
            end if
         end if
      case default
         if (is_literal_tree_node(node)) then
            postfix = char_utf8(node%c(1)%min)//postfix
            res = .true.
         else if (is_char_class_tree_node(node)) then
            continue
         else
            res = .false.
         end if
      end select
   end subroutine get_postfix_literal_internal


!=====================================================================!


   pure function extract_same_part_prefix (a, b) result(res)
      use :: forgex_utf8_m
      implicit none
      character(*), intent(in) :: a, b
      character(:), allocatable :: res

      character(:), allocatable :: buf
      integer :: i, ie, n
      res = ''
      buf = ''
      n = min(len(a), len(b))
      do i = 1, n
         if (a(i:i) == b(i:i)) then
            buf = buf//a(i:i)
         else
            exit
         end if
      end do

      ! Handling UTF8 fragment bytes
      n = len(buf)
      i = 1
      do while (i <= n)
         ie = idxutf8(buf, i)
         if (n < ie) exit

         if (is_valid_multiple_byte_character(buf(i:ie))) then
            res = res//adjustl_multi_byte(buf(i:ie))
         end if
         i = ie + 1
      end do

   end function extract_same_part_prefix


   pure function extract_same_part_postfix (a, b) result(res)
      use :: forgex_utf8_m
      implicit none
      character(*), intent(in) :: a, b
      character(:), allocatable :: res
      
      character(:), allocatable :: buf
      integer :: i, ii, n, diff, ie
      character(:), allocatable :: short_s, long_s
      
      res = ''
      buf = ''

      if (len(a) < len(b)) then
         short_s = a 
         long_s = b
      else
         short_s = b
         long_s = a
      end if
 
      n = min(len(a), len(b))
      diff = max(len(a), len(b)) - n

      do i = n, 1, -1
         ii = i + diff
         if (short_s(i:i) == long_s(ii:ii)) then
            buf = a(i:i)//buf
         else
            exit
         end if
      end do

      n = len(buf)
      i= 1
      do while (i <= n)
         ie = idxutf8(buf, i)
         if (n < ie) exit
         
         if (is_valid_multiple_byte_character(buf(i:ie))) then
            res = res//adjustl_multi_byte(buf(i:ie))
         end if
         i = ie + 1
      end do
   end function extract_same_part_postfix


   pure function extract_same_part_middle(left_middle, right_middle) result(middle)
      use :: forgex_utf8_m
      implicit none
      character(*), intent(in) :: left_middle, right_middle
      character(:), allocatable :: middle
      
      integer :: i, j, max_len, len_left, len_right, len_tmp
      character(:), allocatable :: tmp_middle

      len_left = len(left_middle)
      len_right = len(right_middle)
      max_len = 0
      middle = ''

      ! Compare all substring
      do i = 1, len_left
         do j = 1, len_right
            if (left_middle(i:i) == right_middle(j:j)) then
               tmp_middle = ''
               len_tmp = 0

               ! Check whether match strings or not.
               do while (i+len_tmp <= len_left .and. j+len_tmp <= len_right)
                  if (left_middle(i:i+len_tmp) == right_middle(j:j+len_tmp)) then
                     tmp_middle = left_middle(i:i+len_tmp)
                     len_tmp = len(tmp_middle)
                  else
                     exit
                  end if
               end do

               ! Store the longest common part.
               if (len_tmp > max_len) then
                  max_len = len(tmp_middle)
                  middle = tmp_middle
               end if
            end if
         end do
      end do
   end function extract_same_part_middle
      
end module forgex_syntax_tree_optimize_m