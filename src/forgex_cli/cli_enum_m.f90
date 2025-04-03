! Fortran Regular Expression (Forgex)
!
! MIT License
!
! (C) Amasaki Shinobu, 2023-2025
!     A regular expression engine for Fortran.
!     forgex_cli_enum_m module is a part of Forgex.
!
module forgex_cli_enum_m
   implicit none
   
   enum, bind(c)
      enumerator :: type_undefined = 0
      enumerator :: type_integer
      enumerator :: type_real
      enumerator :: type_character
   end enum

   enum, bind(c)
      enumerator :: SUCCESS = 0
      enumerator :: ERR_KEY_ALREADY_EXISTS
      enumerator :: ERR_NOT_FOUND
   end enum
end module forgex_cli_enum_m
