class ZCL_APPLICATION_LOG_WRAPPER definition
  public
  create public .

*"* public components of class ZCL_APPLICATION_LOG_WRAPPER
*"* do not include other source files here!!!
public section.
  type-pools ABAP .

  data ERROR_COUNT type I read-only .
  data OTHER_COUNT type I read-only .
  data WARNING_COUNT type I read-only .

  methods ADD_BALMI
    importing
      !BALMI type BALMI .
  methods ADD_BAPIRET2
    importing
      !BAPIRET2 type BAPIRET2_TAB
      !ROW type BAPIRET2-ROW default -1 .
  methods ADD_BDCMSGCOLL
    importing
      !BDCMSGCOLL type TAB_BDCMSGCOLL .
  methods ADD_BDIDOCSTAT
    importing
      !BDIDOCSTAT type BDIDOCSTAT .
  methods ADD_COLLECTOR
    importing
      !MESSAGES type ref to ZMESSAGE_COLLECTOR .
  methods ADD_EXCEPTION
    importing
      !MSGTY type SYMSGTY
      !EXCEPTION type ref to CX_ROOT .
  methods ADD_EXCEPTION_EVERYTHING
    importing
      !TYPE type SYMSGTY default 'E'
      !I_NO_LOCATION type ABAP_BOOL default ABAP_FALSE
      !EXCEPTION type ref to CX_ROOT .
  methods ADD_EXCEPTION_TEXT
    importing
      !TYPE type SYMSGTY default 'E'
      !EXCEPTION type ref to CX_ROOT .
  methods ADD_EXTENDED
    importing
      !V1 type ANY optional
      !V2 type ANY optional
      !V3 type ANY optional
      !V4 type ANY optional
      !V5 type ANY optional
      !V6 type ANY optional
      !V7 type ANY optional
      !V8 type ANY optional
      !V9 type ANY optional
      !V10 type ANY optional
      !V11 type ANY optional
      !V12 type ANY optional
      !V13 type ANY optional
      !V14 type ANY optional
      !V15 type ANY optional
      !V16 type ANY optional
      !V17 type ANY optional
      !V18 type ANY optional
      !V19 type ANY optional
      !V20 type ANY optional .
  methods ADD_FREE_TEXT
    importing
      !TYPE type SYMSGTY
      !TEXT type C optional
      !STRING type STRING optional .
  methods ADD_IF_T100_MESSAGE
    importing
      !IIF_T100_MESSAGE type ref to IF_T100_MESSAGE
      !I_TYPE type BAL_S_MSG-MSGTY default 'E' .
  methods ADD_MSG
    importing
      value(MSG) type BAL_S_MSG .
  methods ADD_SELECTIONS
    importing
      value(REPID) type SY-REPID .
  methods ADD_STRING
    importing
      !TYPE type BALMI-MSGTY default 'I'
      !ID type BALMI-MSGID optional
      !NUMBER type BALMI-MSGNO default '000'
      !STRING type STRING .
  methods ADD_SYST .
  methods ADD_TIMESTAMP
    importing
      !MSGNO type BALMI-MSGNO .
  methods ADD_TIMESTAMP_AND_TEXT
    importing
      !I_TEXT type C optional .
  methods ADD_VALUES
    importing
      !TYPE type BALMI-MSGTY default 'E'
      !ID type BALMI-MSGID optional
      !NUMBER type BALMI-MSGNO
      !V1 type ANY optional
      !V2 type ANY optional
      !V3 type ANY optional
      !V4 type ANY optional .
  methods ADD_ZCX_AUTO_ERROR
    importing
      !TYPE type BALMI-MSGTY default 'E'
      !EXCEPTION type ref to ZCX_AUTO_ERROR .
  methods CONSTRUCTOR
    importing
      !OBJECT type BALHDR-OBJECT optional
      !SUBOBJECT type BALHDR-SUBOBJECT optional
      !EXTERNAL_ID type CLIKE optional
      !ALTCODE type CLIKE optional
      !MSGID type SY-MSGID optional
      !EXTENDED_LOG type ABAP_BOOL default ABAP_FALSE
      !APPLICATION_LOG_OPENED_MESSAGE type ABAP_BOOL default ABAP_FALSE
      value(USEREXITP) type BAL_S_CLBK-USEREXITP optional
      value(USEREXITF) type BAL_S_CLBK-USEREXITF optional .
  methods GET_EXTERNAL_ID
    returning
      value(R_VALUE) type BAL_S_LOG-EXTNUMBER .
  methods GET_LOG_INFORMATION
    importing
      !I_LANGU type SPRAS default 'U'
      !I_SEPARATOR type C default '/'
    returning
      value(R_VALUE) type TEXT200 .
  methods GET_LOG_LABEL
    importing
      !I_SEPARATOR type C default '/'
    returning
      value(R_VALUE) type TEXT150 .
  methods GET_LOG_NUMBER
    returning
      value(LOGNUMBER) type BALOGNR .
  methods POPUP_DISPLAY .
  methods SET_EXTERNAL_ID
    importing
      !EXTERNAL_ID type CLIKE .
  methods SOMETHING_IS_PUT_TO_LOG
    returning
      value(R_VALUE) type ABAP_BOOL .
  methods WRITE .
protected section.
*"* protected components of class ZCL_APPLICATION_LOG_WRAPPER
*"* do not include other source files here!!!
private section.
*"* private components of class ZCL_APPLICATION_LOG_WRAPPER
*"* do not include other source files here!!!

  data EXTENDED_LOG type ABAP_BOOL .
  data HANDLE type BALLOGHNDL .
  data HDR type BAL_S_LOG .
  data MSGID type SY-MSGID .

  methods ADD_EXCEPTION_ONE
    importing
      !TYPE type SYMSGTY default 'E'
      !I_NO_LOCATION type ABAP_BOOL
      !EXCEPTION type ref to CX_ROOT .
  methods CONCATENATE_VAR
    importing
      !VAR type ANY
    changing
      !STRING type STRING .
  methods GET_POPUP_PROFILE
    returning
      value(PROFILE) type BAL_S_PROF .
  methods GET_PROBCLASS
    importing
      !TYPE type MSGTY
    returning
      value(PROBCLASS) type BALPROBCL .
ENDCLASS.



CLASS ZCL_APPLICATION_LOG_WRAPPER IMPLEMENTATION.


method write.

  data:
    handles type bal_t_logh.

  append handle to handles.

  call function 'BAL_DB_SAVE'
    exporting
      i_t_log_handle = handles.

endmethod.


method something_is_put_to_log.
  if  me->error_count > 0 or
      me->other_count > 0 or
      me->warning_count > 0.
    r_value = abap_true.
  endif.
endmethod.


method set_external_id.

  hdr-extnumber = external_id.

  call function 'BAL_LOG_HDR_CHANGE'
    exporting
      i_log_handle = handle
      i_s_log      = hdr.

endmethod.


method popup_display.

  data:
    profile type bal_s_prof,
    handles type bal_t_logh.

  profile = get_popup_profile( ).

  append handle to handles.

  call function 'BAL_DSP_LOG_DISPLAY'
    exporting
      i_s_display_profile = profile
      i_t_log_handle      = handles
    exceptions
      others              = 4.

endmethod.


method get_probclass.
  case type.
    when 'E' or 'A' or 'X'.
      probclass = '1'.
      add 1 to error_count.
    when 'W'.
      probclass = '3'.
      add 1 to warning_count.
    when others.
      probclass = '4'.
      add 1 to other_count.
  endcase.
endmethod.


method get_popup_profile.

* get a predefined profile for the given form of representation
  call function 'BAL_DSP_PROFILE_POPUP_GET'
    importing
      e_s_display_profile = profile.

* use grid for display
  profile-use_grid = 'X'.

* set current report to allow saving of variants
  profile-disvariant-report = sy-repid.

* When other ALV lists are used in the report, a handle should be
* specified in order to distinguish between display variants of
* different lists.
  profile-disvariant-handle = 'ZMESSAGE_COLLECTOR'.

* set output colors according to the problem class of the messages
  profile-colors-probclass1 = 3.    " normal messages
  profile-colors-probclass4 = 4.    " header line

* do not cut messages in the application log output
  profile-cwidth_opt = 'X'.

endmethod.


method get_log_number.
*--------------------------------------------------------------------*
* Get application log number
*
* The application log number is only initialized after first call to
* WRITE method. Before this it contains a placeholder.
*--------------------------------------------------------------------*

  call function 'BAL_LOG_HDR_READ'
    exporting
      i_log_handle = handle
    importing
      e_lognumber  = lognumber.

endmethod.


method get_log_label.
  concatenate
    hdr-object
    hdr-subobject
    hdr-extnumber
    into r_value
    separated by i_separator.
endmethod.


method get_log_information.
  case i_langu.
    when 'E'.
      r_value = 'Additional information from application log (SLG1):'.
    when others.
      r_value = 'Lisätietoa application logista (SLG1):'.
  endcase.

  concatenate
    r_value
    hdr-object
    into r_value
    separated by ' '.

  concatenate
    r_value
    hdr-subobject
    hdr-extnumber
    into r_value
    separated by i_separator.

  concatenate
    r_value
    '.'
    into r_value.
endmethod.


method get_external_id.
  r_value = hdr-extnumber.
endmethod.


method constructor.

  me->msgid        = msgid.
  me->extended_log = extended_log.

  hdr-object    = object.
  hdr-subobject = subobject.

  hdr-extnumber = external_id.         " External ID
  hdr-aldate    = sy-datum.            " Date
  hdr-altime    = sy-uzeit.            " Time
  hdr-aluser    = sy-uname.            " User name
  hdr-altcode   = msgid.               " Transaction
  hdr-alprog    = sy-repid.            " Report

  " Fill user exit fields
  hdr-params-callback-userexitp = userexitp.
  hdr-params-callback-userexitf = userexitf.

  if altcode is initial.
    hdr-altcode = msgid.               " Transaction
  else.
    hdr-altcode = altcode.
  endif.

  call function 'BAL_LOG_CREATE'
    exporting
      i_s_log      = hdr
    importing
      e_log_handle = handle.

  if application_log_opened_message = abap_true.
    "Application log &1 &2 opened"
    message s001 with object subobject.
  endif.

endmethod.


method concatenate_var.

  data:
    tmp(50) type c.

  write var to tmp.
  shift tmp left deleting leading space.

  if string is initial.
    string = tmp.
  elseif not string cp '*:'.
    concatenate string tmp into string separated by '/'.
  else.
    concatenate string tmp into string separated by space.
  endif.

endmethod.


method add_zcx_auto_error.

  add_values(
    type   = type
    id     = exception->id
    number = exception->no
    v1     = exception->v1
    v2     = exception->v2
    v3     = exception->v3
    v4     = exception->v4 ).

endmethod.


method add_values.

  data:
    b type bal_s_msg.

  b-msgty = type.
  b-msgid = id.
  b-msgno = number.
  b-msgv1 = v1.
  b-msgv2 = v2.
  b-msgv3 = v3.
  b-msgv4 = v4.

  add_msg( b ).

endmethod.


method add_timestamp_and_text.

  data:
    text  type char200,
    type  type symsgty,
    probclass type balprobcl,
    msgtext   type char200.

  type = 'I'.

  get time.

  write sy-datum to msgtext.
  write sy-uzeit to text.
  concatenate msgtext text into msgtext separated by space.
  concatenate msgtext i_text into msgtext separated by space.

  probclass = get_probclass( type ).

  call function 'BAL_LOG_MSG_ADD_FREE_TEXT'
    exporting
      i_log_handle = handle
      i_msgty      = type
      i_probclass  = probclass
      i_text       = msgtext.

endmethod.


method add_timestamp.

  data:
    b type bal_s_msg.

  get time.

  b-msgty = 'I'.
  b-msgid = msgid.
  b-msgno = msgno.

  write sy-datum to b-msgv1.
  write sy-uzeit to b-msgv2.

  add_msg( b ).

endmethod.


method add_syst.

  data:
    b type bal_s_msg.

  check not sy-msgid is initial.

  b-msgty = sy-msgty.
  b-msgid = sy-msgid.
  b-msgno = sy-msgno.
  b-msgv1 = sy-msgv1.
  b-msgv2 = sy-msgv2.
  b-msgv3 = sy-msgv3.
  b-msgv4 = sy-msgv4.

  add_msg( b ).

endmethod.


method add_string.

  data:
    begin of v,
      msgv1 type balmi-msgv1,
      msgv2 type balmi-msgv2,
      msgv3 type balmi-msgv3,
      msgv4 type balmi-msgv4,
    end of v.

  v = string.

  add_values(
    type   = type
    id     = id
    number = number
    v1     = v-msgv1
    v2     = v-msgv2
    v3     = v-msgv3
    v4     = v-msgv4 ).

endmethod.


method add_selections.

  data:
    textpool   type table of textpool,
    txt        type textpool,
    selections type rsparams_tt,
    s          type rsparams,
    v1         type balmi-msgv1,
    option     type balmi-msgv2.

  call function 'RS_REFRESH_FROM_SELECTOPTIONS'
    exporting
      curr_report     = repid
    tables
      selection_table = selections
    exceptions
      others          = 4.

  check sy-subrc = 0.

  read textpool repid into textpool language sy-langu.

  loop at selections into s
    where not sign   is initial
       or not option is initial
       or not low    is initial
       or not high   is initial.

    read table textpool into txt with key key = s-selname.

    if txt-id = 'S'.
      concatenate txt-entry+8 ':' into v1.
    else.
      concatenate txt-entry ':' into v1.
    endif.

    concatenate s-selname v1 into v1 separated by space.

    concatenate s-sign s-option into option separated by space.

*   message i002(ZID056B).
    add_values(
      type    = 'I'
      id     = 'ZID056B'
      number = '002'
      v1     = v1
      v2     = option
      v3     = s-low
      v4     = s-high ).
  endloop.

endmethod.


method add_msg.

  if msg-msgid is initial.
    msg-msgid = msgid.
  endif.

  msg-probclass = get_probclass( msg-msgty ).

  call function 'BAL_LOG_MSG_ADD'
    exporting
      i_log_handle = handle
      i_s_msg      = msg.

endmethod.


method add_if_t100_message.

  " Set message variable in SY
  cl_message_helper=>set_msg_vars_for_if_t100_msg( iif_t100_message ).

  data s_msg type bal_s_msg.
  s_msg-msgty = i_type.
  s_msg-msgid = iif_t100_message->t100key-msgid.
  s_msg-msgno = iif_t100_message->t100key-msgno.
  s_msg-msgv1 = sy-msgv1.
  s_msg-msgv2 = sy-msgv2.
  s_msg-msgv3 = sy-msgv3.
  s_msg-msgv4 = sy-msgv4.

  add_msg( s_msg ).

endmethod.


method add_free_text.

  data:
    probclass type balprobcl,
    msgtext   type char200.

  probclass = get_probclass( type ).

  if string is supplied.
    msgtext = string.
  else.
    msgtext = text.
  endif.

  call function 'BAL_LOG_MSG_ADD_FREE_TEXT'
    exporting
      i_log_handle = handle
      i_msgty      = type
      i_probclass  = probclass
      i_text       = msgtext.

endmethod.


method add_extended.

  data:
    s type string.

  check extended_log = abap_true.

  define vars.
    if v&1 is supplied.
      concatenate_var( exporting var = v&1 changing string = s ).
    endif.
  end-of-definition.

  vars: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20.

  add_string( s ).

endmethod.


method ADD_EXCEPTION_TEXT.
  data:
    str   type string.
  if exception is bound.
    str = exception->get_text( ).
    add_free_text( type = type string = str ).
  endif.
endmethod.


method add_exception_one.
  data:
    str           type string,
    program_name  type syrepid,
    include_name  type syrepid,
    source_line	  type i,
    source_line_c type c length 10,
    describer_r   type ref to cl_abap_typedescr.

  if exception is bound.
    str = exception->get_text( ).
    add_free_text( type = type string = str ).

    if i_no_location = abap_false.
      describer_r = cl_abap_typedescr=>describe_by_object_ref( exception ).
      add_free_text( type = type text = describer_r->absolute_name ).
      call method exception->get_source_position
        importing
          program_name = program_name
          include_name = include_name
          source_line	 = source_line.
      add_free_text( type = type text = program_name ).
      add_free_text( type = type text = include_name ).
      write source_line to source_line_c left-justified.
      add_free_text( type = type text = source_line_c ).
    endif.
  endif.
endmethod.


method add_exception_everything.
  if exception is bound.
    add_exception_one(
      type          = type
      i_no_location = i_no_location
      exception     = exception
      ).
    if exception->previous is bound.
      add_free_text( type = type string = 'PREVIOUS EXCEPTION DATA IS BELOW:' ).
      add_exception_one(
        type          = type
        i_no_location = i_no_location
        exception     = exception->previous
        ).
      if exception->previous->previous is bound.
        add_free_text( type = type string = 'PREVIOUS->PREVIOUS EXCEPTION DATA IS BELOW:' ).
        add_exception_one(
          type          = type
          i_no_location = i_no_location
          exception     = exception->previous->previous
          ).
        if exception->previous->previous->previous is bound.
          add_free_text( type = type string = 'PREVIOUS->PREVIOUS->PREVIOUS EXCEPTION DATA IS BELOW:' ).
          add_exception_one(
            type          = type
            i_no_location = i_no_location
            exception     = exception->previous->previous->previous
            ).
          if exception->previous->previous->previous->previous is bound.
            add_free_text( type = type string = 'PREVIOUS->PREVIOUS->PREVIOUS->PREVIOUS EXCEPTION DATA IS BELOW:' ).
            add_exception_one(
              type          = type
              i_no_location = i_no_location
              exception     = exception->previous->previous->previous->previous
              ).
          endif.
        endif.
      endif.
    endif.
  endif.
endmethod.


method add_exception.

  data:
    exc type bal_s_exc.

  exc-msgty     = msgty.
  exc-exception = exception.
  exc-probclass = get_probclass( msgty ).

  call function 'BAL_LOG_EXCEPTION_ADD'
    exporting
      i_log_handle = handle
      i_s_exc      = exc.

endmethod.


method add_collector.

  data:
    msg_tab type bal_t_msg,
    msg     type ref to bal_s_msg.

  messages->get_messages( importing itab = msg_tab ).

  check not msg_tab[] is initial.

  loop at msg_tab reference into msg.
    add_msg( msg->* ).
  endloop.

endmethod.


method add_bdidocstat.

  data:
    b type bal_s_msg.

  b-msgty = bdidocstat-msgty.
  b-msgid = bdidocstat-msgid.
  b-msgno = bdidocstat-msgno.
  b-msgv1 = bdidocstat-msgv1.
  b-msgv2 = bdidocstat-msgv2.
  b-msgv3 = bdidocstat-msgv3.
  b-msgv4 = bdidocstat-msgv4.

  add_msg( b ).

endmethod.


method add_bdcmsgcoll.

  data:
    r type ref to bdcmsgcoll,
    b type bal_s_msg.

  loop at bdcmsgcoll reference into r.
    b-msgty = r->msgtyp.
    b-msgid = r->msgid.
    b-msgno = r->msgnr.
    b-msgv1 = r->msgv1.
    b-msgv2 = r->msgv2.
    b-msgv3 = r->msgv3.
    b-msgv4 = r->msgv4.

    add_msg( b ).
  endloop.

endmethod.


method add_bapiret2.

  data:
    r type bapiret2,
    b type bal_s_msg.

  loop at bapiret2 into r.
    check r-row = row
       or row   = -1.

    b-msgty = r-type.
    b-msgid = r-id.
    b-msgno = r-number.
    b-msgv1 = r-message_v1.
    b-msgv2 = r-message_v2.
    b-msgv3 = r-message_v3.
    b-msgv4 = r-message_v4.

    add_msg( b ).
  endloop.

endmethod.


method add_balmi.

  data:
    msg type bal_s_msg.

  move-corresponding balmi to msg.
  add_msg( msg ).

endmethod.
ENDCLASS.