#ifdef PURE
#define pure
#endif
module forgex_lazy_dfa_graph_m
   use, intrinsic :: iso_fortran_env, only: int32
   use :: forgex_parameters_m
   use :: forgex_lazy_dfa_node_m
   implicit none
   private

   type, public :: dfa_graph_t
      type(dfa_state_node_t), allocatable :: nodes(:)
      integer(int32) :: dfa_base = DFA_STATE_BASE
      integer(int32) :: dfa_limit = DFA_STATE_LIMIT
      integer(int32) :: dfa_top = DFA_INVALID_INDEX
   contains
      procedure :: preprocess => lazy_dfa__preprocess
      procedure :: registered => lazy_dfa__registered_index
      procedure :: add_transition => lazy_dfa__add_transition
   end type dfa_graph_t

contains

   pure subroutine lazy_dfa__preprocess (self)
      implicit none
      class(dfa_graph_t), intent(inout) :: self

      integer(int32) :: i, base, limit

      ! Initialize DFA
      base = self%dfa_base
      limit = self%dfa_limit

      allocate(self%nodes(base:limit))

      do i = base, limit
         self%nodes(i)%own_i = i
      end do
      self%dfa_top = DFA_INITIAL_INDEX

   end subroutine lazy_dfa__preprocess


   ! DFA状態がすでに登録されているかを、添字で返す。登録されていなければDFA_INVALID_INDEXを返す。
   pure function lazy_dfa__registered_index(self, set) result(res)
      use :: forgex_nfa_state_set_m
      implicit none
      class(dfa_graph_t), intent(in) :: self
      type(nfa_state_set_t), intent(in) :: set
      integer(int32) :: res

      integer(int32) :: i
      logical :: is_registered

      res = DFA_INVALID_INDEX
      do i = DFA_INITIAL_INDEX, self%dfa_top
         is_registered = equivalent_nfa_state_set(self%nodes(i)%nfa_set, set)
         if (is_registered) then
            res = i
            return
         end if
      end do
   end function lazy_dfa__registered_index


   pure subroutine lazy_dfa__add_transition(self, state_set, src, dst, segments)
      use :: forgex_segment_m
      use :: forgex_nfa_state_set_m
      implicit none
      class(dfa_graph_t), intent(inout) :: self
      type(nfa_state_set_t), intent(in) :: state_set
      integer, intent(in) :: src, dst
      type(segment_t), intent(in) :: segments(:)

      type(dfa_transition_t) :: tra
      integer :: j

      tra%c_top = size(segments, dim=1)
      allocate(tra%c(tra%c_top))
      tra%c(:) = segments(:)
      tra%dst = dst
      tra%nfa_set = state_set

      ! j = self%nodes(src)%tra_top + 1
      ! self%nodes(src)%transition(j) = tra
      ! self%nodes(src)%tra_top = j + 1

      if (self%nodes(src)%get_tra_top() == DFA_NOT_INIT_TRAENSITION_TOP) then
         call self%nodes(src)%init_transition()
      end if

      call self%nodes(src)%increment_tra_top() ! tra_top becomes 1

      j = self%nodes(src)%get_tra_top()
      tra%own_j = j


      self%nodes(src)%transition(j) = tra
      self%nodes(src)%transition(j)%own_j = j

   end subroutine lazy_dfa__add_transition


end module forgex_lazy_dfa_graph_m