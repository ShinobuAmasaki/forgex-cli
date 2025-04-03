! Fortran Regular Expression (Forgex)
!
! MIT License
!
! (C) Amasaki Shinobu, 2023-2025
!     A regular expression engine for Fortran.
!     forgex_cli_keys_hash_table_m module is a part of Forgex.
!
module forgex_cli_keys_hash_table
   implicit none
   private

      ! 20 Keys
   character(*), parameter, public :: k_pattern        = "pattern"
   character(*), parameter, public :: k_text           = "text"
   character(*), parameter, public :: k_runs_engine    = "runs engine"
   character(*), parameter, public :: k_matching_result= "result"

   character(*), parameter, public :: k_parse_time     = "parse time"
   character(*), parameter, public :: k_nfa_time       = "compile nfa time"
   character(*), parameter, public :: k_literal_time   = "extract literal time"
   character(*), parameter, public :: k_total_time     = "total time"
   character(*), parameter, public :: k_dfa_init_time  = "dfa initialize time"
   character(*), parameter, public :: k_dfa_compile_time = 'dfa compile time'
   character(*), parameter, public :: k_matching_time  = "search time"

   character(*), parameter, public :: k_tree_count     = "tree node count"
   character(*), parameter, public :: k_tree_allocated = "tree node allocated"
   character(*), parameter, public :: k_nfa_count      = "nfa states"
   character(*), parameter, public :: k_nfa_allocated  = "nfa states allocated"
   character(*), parameter, public :: k_dfa_count      = "dfa states"
   
   character(*), parameter, public :: k_literal_all    = "extracted literal"
   character(*), parameter, public :: k_literal_pre    = "extracted prefix"   
   character(*), parameter, public :: k_literal_mid    = "extracted middle"
   character(*), parameter, public :: k_literal_post   = "extracted suffix"
end module forgex_cli_keys_hash_table