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
   public :: all_literals
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
      logical :: each_res

      chara = ''

      call get_postfix_literal_internal(tree%nodes, tree%top, chara, each_res)

   end function get_postfix_literal


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


   pure recursive subroutine all_literals(tree, idx, literal)
      use :: forgex_syntax_tree_node_m
      implicit none
      type(tree_node_t), intent(in) :: tree(:)
      integer(int32), intent(in) :: idx
      character(:), allocatable, intent(inout) :: literal
      type(tree_node_t) :: node

      node = tree(idx)

      if (node%op == op_concat) then
         call all_literals(tree, node%left_i, literal) 
         if (literal == '') return
         call all_literals(tree, node%right_i, literal)
         if (literal == '') return
      else if (is_literal_tree_node(node)) then
         literal = literal//char_utf8(node%c(1)%min)
      else
         literal = ''
      end if

   end subroutine all_literals
   

   pure recursive subroutine get_prefix_literal_internal(tree, idx, prefix, res)
      use :: forgex_parameters_m
      implicit none
      type(tree_node_t), intent(in) :: tree(:)
      integer(int32), intent(in) :: idx
      character(:), allocatable, intent(inout) :: prefix
      logical, intent(inout) :: res

      logical :: res_left, res_right
      type(tree_node_t) :: node
      character(:), allocatable :: candidate1, candidate2
      integer :: j, n
      
      node = tree(idx)
      res_left = .false.
      res_right = .false.
      candidate1 = ''
      candidate2 = ''

      select case (node%op)
      case (op_concat)
         call get_prefix_literal_internal(tree, node%left_i, prefix, res_left)

         if (res_left) then
            call get_prefix_literal_internal(tree, node%right_i, prefix, res_right)
         end if

         res = res_left .and. res_right

      case(op_union)
         call get_prefix_literal_internal(tree, node%left_i, candidate1, res_left)
         call get_prefix_literal_internal(tree, node%right_i, candidate2, res_right)
         prefix = extract_same_part_prefix(candidate1, candidate2)
         res = .false.
      case(op_repeat)
         n = node%min_repeat
         do j = 1, n
            call get_prefix_literal_internal(tree, node%left_i, prefix, res_right)
         end do
         res = res_right
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


   pure recursive subroutine get_postfix_literal_internal(tree, idx, postfix, res)
      implicit none
      type(tree_node_t), intent(in) :: tree(:)
      integer(int32), intent(in) :: idx
      character(:), allocatable, intent(inout) :: postfix
      logical, intent(inout) :: res
      
      logical :: res_left, res_right, unused
      type(tree_node_t) :: node
      character(:), allocatable :: candidate1, candidate2
      integer :: n, j

      node = tree(idx)
      res_left = .false.
      res_right = .false.
      candidate1 = ''
      candidate2 = ''

      select case (node%op)
      case (op_concat)
         call get_postfix_literal_internal(tree, node%right_i, postfix, res_right)

         if (res_right) then
            call get_postfix_literal_internal(tree, node%left_i, candidate1, res_left)
         end if

         if (res_right) then
            if (postfix == "") then
                postfix = candidate1
            else
               postfix = candidate1//postfix
            end if
         end if

         res = res_left .and. res_right
      case (op_union)
         call get_postfix_literal_internal(tree, node%left_i, candidate1, res_left)
         call get_postfix_literal_internal(tree, node%right_i, candidate2, res_right)
         postfix = extract_same_part_postfix(candidate1, candidate2)
         res = postfix == ""
         ! res = (postfix == "" .or. res_left .or. res_right)
         ! res = .true.
      case(op_repeat)
         n = node%min_repeat
         do j = 1, n
            call get_postfix_literal_internal(tree, node%left_i, postfix, res_right)
         end do
         res = res_right
      case(op_closure)
         ! +に対する処理
         if (node%parent_i /= 0) then
            if(tree(node%parent_i)%op == op_concat) then
               ! 親の演算子が連結の場合、
               
               ! 姉ノードのリテラルを抽出し、子ノードのリテラルがそれと一致する場合は真を返す
               if (tree(node%parent_i)%right_i == node%own_i) then
                  call get_postfix_literal_internal(tree, tree(node%parent_i)%left_i, candidate1, res_right)
               else
                  candidate1 = ''
               end if

               call get_postfix_literal_internal(tree, node%left_i, candidate2, res_left)   
               if (candidate1 == candidate2) then
                  postfix = ''
                  res = .true.
                  return
               endif
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

end module forgex_syntax_tree_optimize_m