module forgex_cli_print_m
   implicit none
   private

   character(*), parameter :: parse_time     = "parse time:"
   character(*), parameter :: nfa_time       = "compile nfa time:"
   character(*), parameter :: memory         = "memory (estimated):"
   character(*), parameter :: nfa_count      = "nfa states:"
   character(*), parameter :: nfa_allocated  = "nfa states allocated:"
   character(*), parameter :: tree_count     = "tree node count:"
   character(*), parameter :: tree_allocated = "tree node allocated:"

   character(*), parameter :: literal_time   = "extract time:"
   character(*), parameter :: literal_all    = "extracted literal:"
   character(*), parameter :: literal_pre    = "extracted prefix:"
   character(*), parameter :: literal_mid    = "extracted middle:"
   character(*), parameter :: literal_post   = "extracted suffix:"

contains

end module forgex_cli_print_m