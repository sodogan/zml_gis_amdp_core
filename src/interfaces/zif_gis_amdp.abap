INTERFACE zif_gis_amdp
  PUBLIC .
  TYPES:BEGIN OF ty_instances,
          id  TYPE string,
          ref TYPE REF TO zcl_gis_amdp_base,
        END OF ty_instances.


  TYPES:tt_instances TYPE HASHED TABLE OF ty_instances WITH UNIQUE KEY id.
  INTERFACES if_amdp_marker_hdb .
  INTERFACES if_badi_interface.

ENDINTERFACE.