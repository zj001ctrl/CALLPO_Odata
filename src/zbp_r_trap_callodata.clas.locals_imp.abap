CLASS lhc_zr_trap_callodata DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.
    METHODS:
      get_global_authorizations FOR GLOBAL AUTHORIZATION
        IMPORTING
        REQUEST requested_authorizations FOR ZrTrapCallodata
        RESULT result,
      get FOR MODIFY
        IMPORTING keys FOR ACTION ZrTrapCallodata~get.

    METHODS post FOR MODIFY
      IMPORTING keys FOR ACTION ZrTrapCallodata~post.
ENDCLASS.

CLASS lhc_zr_trap_callodata IMPLEMENTATION.
  METHOD get_global_authorizations.
  ENDMETHOD.
  METHOD get.

    DATA:
      ls_entity_key    TYPE z_scm_po_odata=>tys_purchase_order_type,
      ls_business_data TYPE z_scm_po_odata=>tys_purchase_order_type,
      lo_http_client   TYPE REF TO if_web_http_client,
      lo_resource      TYPE REF TO /iwbep/if_cp_resource_entity,
      lo_client_proxy  TYPE REF TO /iwbep/if_cp_client_proxy,
      lo_request       TYPE REF TO /iwbep/if_cp_request_read,
      lo_response      TYPE REF TO /iwbep/if_cp_response_read.

    DATA lv_error_msg TYPE string.
    READ ENTITIES OF zr_trap_callodata IN LOCAL MODE
         ENTITY ZrTrapCallodata
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(results).
    DELETE results WHERE purchaseorder IS INITIAL.
    CHECK results IS NOT INITIAL.
    READ TABLE results ASSIGNING FIELD-SYMBOL(<ls_results>) INDEX 1.


    TRY.
        " Create http client
        DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
                                                     comm_scenario  = 'Z_CS_CALL_PO_ODATA'
                                                     comm_system_id = 'Z_OBS_CALL_PO_REST' ).
        "service_id     = '<Service Id>' ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).
        lo_client_proxy = /iwbep/cl_cp_factory_remote=>create_v4_remote_proxy(
          EXPORTING
             is_proxy_model_key       = VALUE #( repository_id       = 'DEFAULT'
                                                 proxy_model_id      = 'Z_SCM_PO_ODATA'
                                                 proxy_model_version = '0001' )
            io_http_client             = lo_http_client
"            iv_relative_service_root   = '<service_root>'
             iv_relative_service_root   = '' ).

        ASSERT lo_http_client IS BOUND.


        " Set entity key
        ls_entity_key = VALUE #(
                  purchase_order  = <ls_results>-Purchaseorder ).

        " Navigate to the resource
        lo_resource = lo_client_proxy->create_resource_for_entity_set( 'PURCHASE_ORDER' )->navigate_with_key( ls_entity_key ).

        " Execute the request and retrieve the business data
        lo_response = lo_resource->create_request_for_read( )->execute( ).
        lo_response->get_business_data( IMPORTING es_business_data = ls_business_data ).

        <ls_results>-Response = xco_cp_json=>data->from_abap( ls_business_data )->to_string(  ).

      CATCH /iwbep/cx_cp_remote INTO DATA(lx_remote).
        " Handle remote Exception
        " It contains details about the problems of your http(s) connection
        lv_error_msg = lx_remote->get_text(  ).

      CATCH /iwbep/cx_gateway INTO DATA(lx_gateway).
        " Handle Exception
        lv_error_msg = lx_gateway->get_text(  ).
      CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
        " Handle Exception
        RAISE SHORTDUMP lx_web_http_client_error.
        lv_error_msg = lx_web_http_client_error->get_text( ).

      CATCH cx_http_dest_provider_error INTO DATA(lx_cx_http_dest_provider_error).
        lv_error_msg = lx_cx_http_dest_provider_error->get_text( ).

    ENDTRY.
    IF lv_error_msg IS INITIAL.
      <ls_results>-Status = 'Successful'.
      <ls_results>-Criticality = 3 .  "Green
    ELSE.
      <ls_results>-Status = 'Failed'.
      <ls_results>-Criticality = 1. "red
      <ls_results>-Response = lv_error_msg.
    ENDIF.
    MODIFY ENTITIES OF zr_trap_callodata IN LOCAL MODE
           ENTITY zrtrapcallodata
           UPDATE FIELDS ( status criticality response )
           WITH CORRESPONDING #( results )
           FAILED failed
           MAPPED mapped
           REPORTED reported.
  ENDMETHOD.

  METHOD post.
    "申明一个带行项目的结构体
    TYPES:
      BEGIN OF ty_post.
        INCLUDE TYPE z_scm_po_odata=>tys_purchase_order_type.
    TYPES purchase_order_item TYPE z_scm_po_odata=>tyt_purchase_order_item_type.
    TYPES END OF ty_post.



    DATA:
*      ls_business_data TYPE z_scm_po_odata=>tys_purchase_order_type,
      lo_http_client  TYPE REF TO if_web_http_client,
      lo_client_proxy TYPE REF TO /iwbep/if_cp_client_proxy,
      lo_request      TYPE REF TO /iwbep/if_cp_request_create,
      lo_response     TYPE REF TO /iwbep/if_cp_response_create.

    DATA:
      ls_po_deep_post   TYPE ty_post,
      ls_po_post_result TYPE ty_post,
      lv_err_msg        TYPE string.


    READ ENTITIES OF zr_trap_callodata IN LOCAL MODE
         ENTITY ZrTrapCallodata
         ALL FIELDS WITH CORRESPONDING #( keys )
         RESULT DATA(results).
    DELETE results WHERE purchaseorder IS INITIAL.
    CHECK results IS NOT INITIAL.
    READ TABLE results ASSIGNING FIELD-SYMBOL(<result>) INDEX 1.


    TRY.
        " Create http client
        DATA(lo_destination) = cl_http_destination_provider=>create_by_comm_arrangement(
                                                     comm_scenario  = 'Z_CS_CALL_PO_ODATA'
                                                     comm_system_id = 'Z_OBS_CALL_PO_REST'
*                                             service_id     = '<Service Id>'
                                                     ).
        lo_http_client = cl_web_http_client_manager=>create_by_http_destination( lo_destination ).
        lo_client_proxy = /iwbep/cl_cp_factory_remote=>create_v4_remote_proxy(
          EXPORTING
             is_proxy_model_key       = VALUE #( repository_id       = 'DEFAULT'
                                                 proxy_model_id      = 'Z_SCM_PO_ODATA'
                                                 proxy_model_version = '0001' )
            io_http_client             = lo_http_client
*            iv_relative_service_root   = '/sap/opu/odata4/sap/api_purchaseorder_2/srvd_a2x/sap/purchaseorder/0001'
            iv_relative_service_root   = ''). "地址已经配置在Outbound Service上了

        ASSERT lo_http_client IS BOUND.


* Prepare business data
*        ls_business_data = VALUE #(
*                  purchase_order              = 'PurchaseOrder'
*                  purchase_order_type_2       = 'PurchaseOrderType2'
*                  purchase_order_subtype      = 'PurchaseOrderSubtype'
*                  purchasing_document_origin  = 'PurchasingDocumentOrigin'
*                  purchasing_document_proces  = 'PurchasingDocumentProces'
*                  created_by_user             = 'CreatedByUser'
*                  creation_date               = '20170101'
*                  purchase_order_date         = '20170101'
*                  last_change_date_time       = 20170101123000
*                  validity_start_date         = '20170101'
*                  validity_end_date           = '20170101'
*                  language                    = 'Language'
*                  purchase_order_deletion_co  = 'PurchaseOrderDeletionCo'
*                  release_is_not_completed    = abap_true
*                  purchasing_completeness_st  = abap_true
*                  purchasing_processing_stat  = 'PurchasingProcessingStat'
*                  purg_release_sequence_stat  = 'PurgReleaseSequenceStat'
*                  release_code                = 'ReleaseCode'
*                  purchasing_release_strateg  = 'PurchasingReleaseStrateg'
*                  purg_reason_for_doc_cancel  = 'PurgReasonForDocCancel'
*                  company_code                = 'CompanyCode'
*                  purchasing_organization     = 'PurchasingOrganization'
*                  purchasing_group            = 'PurchasingGroup'
*                  supplier                    = 'Supplier'
*                  manual_supplier_address_id  = 'ManualSupplierAddressId'
*                  supplier_address_id         = 'SupplierAddressId'
*                  supplier_resp_sales_person  = 'SupplierRespSalesPerson'
*                  supplier_phone_number       = 'SupplierPhoneNumber'
*                  supplying_supplier          = 'SupplyingSupplier'
*                  supplying_plant             = 'SupplyingPlant'
*                  invoicing_party             = 'InvoicingParty'
*                  customer                    = 'Customer'
*                  purchase_contract           = 'PurchaseContract'
*                  supplier_quotation_externa  = 'SupplierQuotationExterna'
*                  quotation_submission_date   = '20170101'
*                  item_number_interval_for_s  = 'ItemNumberIntervalForS'
*                  payment_terms               = 'PaymentTerms'
*                  cash_discount_1_days        = '1'
*                  cash_discount_2_days        = '1'
*                  net_payment_days            = '1'
*                  cash_discount_1_percent     = '1'
*                  cash_discount_2_percent     = '1'
*                  down_payment_type           = 'DownPaymentType'
*                  down_payment_percentage_of  = '1'
*                  down_payment_amount         = 5550
*                  down_payment_due_date       = '20170101'
*                  incoterms_classification    = 'IncotermsClassification'
*                  incoterms_transfer_locatio  = 'IncotermsTransferLocatio'
*                  incoterms_version           = 'IncotermsVersion'
*                  incoterms_location_1        = 'IncotermsLocation1'
*                  incoterms_location_2        = 'IncotermsLocation2'
*                  is_intrastat_reporting_rel  = abap_true
*                  is_intrastat_reporting_exc  = abap_true
*                  correspnc_external_referen  = 'CorrespncExternalReferen'
*                  correspnc_internal_referen  = 'CorrespncInternalReferen'
*                  pricing_document            = 'PricingDocument'
*                  pricing_procedure           = 'PricingProcedure'
*                  document_currency           = 'DocumentCurrency'
*                  exchange_rate               = '1'
*                  exchange_rate_is_fixed      = abap_true
*                  tax_return_country          = 'TaxReturnCountry'
*                  vatregistration_country     = 'VatregistrationCountry'
*                  purg_aggrgd_prod_cmplnc_su  = 'PurgAggrgdProdCmplncSu'
*                  purg_aggrgd_prod_marketabi  = 'PurgAggrgdProdMarketabi'
*                  purg_aggrgd_sfty_data_shee  = 'PurgAggrgdSftyDataShee'
*                  purg_prod_cmplnc_tot_dngrs  = 'PurgProdCmplncTotDngrs'
*                  purchasing_collective_numb  = 'PurchasingCollectiveNumb' ).
        ls_po_deep_post = VALUE #( purchase_order_type_2   = 'NB'
                                          company_code            = '1310'
                                          purchasing_organization = '1310'
                                          purchasing_group        = '001'
                                          supplier                = '0013300007'
                                          purchase_order_date     = cl_abap_context_info=>get_system_date( )
                                          document_currency       = 'CNY'
                                          purchase_order_item     = VALUE #( ( purchase_order_item         = '00010'
                                                                               material                    = 'SG022'
                                                                               plant                       = '1310'
                                                                               order_quantity              = '10'
                                                                               net_price_amount            = 1000
                                                                               document_currency           = 'CNY'
                                                                               purchase_order_quantity_un  = 'PC' )
                                                                             ( purchase_order_item         = '00020'
                                                                               material                    = 'SG022'
                                                                               plant                       = '1310'
                                                                               order_quantity              = '20'
                                                                               net_price_amount            = 2000
                                                                               document_currency           = 'CNY'
                                                                               purchase_order_quantity_un  = 'PC' ) ) ).


        " Navigate to the resource and create a request for the create operation
        lo_request = lo_client_proxy->create_resource_for_entity_set( 'PURCHASE_ORDER' )->create_request_for_create( ).
        DATA(lo_data_description_root) = lo_request->create_data_descripton_node( ).

        lo_data_description_root->set_properties( VALUE #(  ( |PURCHASE_ORDER_TYPE_2| )
                                                            ( |COMPANY_CODE| )
                                                            ( |PURCHASING_ORGANIZATION| )
                                                            ( |PURCHASING_GROUP| )
                                                            ( |SUPPLIER| )
                                                            ( |PURCHASE_ORDER_DATE| )
                                                            ( |DOCUMENT_CURRENCY| ) ) ).

        DATA(lo_data_description_item) = lo_data_description_root->add_child( 'PURCHASE_ORDER_ITEM' ).

        lo_data_description_item->set_properties( VALUE #(  ( |PURCHASE_ORDER_ITEM| )
                                                            ( |MATERIAL| )
                                                            ( |PLANT| )
                                                            ( |ORDER_QUANTITY| )
                                                            ( |NET_PRICE_AMOUNT| )
                                                            ( |DOCUMENT_CURRENCY| )
                                                            ( |PURCHASE_ORDER_QUANTITY_UN| ) ) ).


        " Set the business data for the created entity
*        lo_request->set_business_data( ls_business_data ).
        lo_request->set_deep_business_data(
          EXPORTING
            is_business_data            = ls_po_deep_post
            io_data_description         = lo_data_description_root
        ).

        lo_response->get_business_data( IMPORTING es_business_data = ls_po_post_result ).
        <result>-response = xco_cp_json=>data->from_abap( ls_po_post_result )->to_string( ).
        <result>-purchaseorder = ls_po_post_result-purchase_order.

        " Execute the request
        lo_response = lo_request->execute( ).

        " Get the after image
*lo_response->get_business_data( IMPORTING es_business_data = ls_business_data ).

      CATCH /iwbep/cx_cp_remote INTO DATA(lx_remote).
        " Handle remote Exception
        " It contains details about the problems of your http(s) connection
        lv_err_msg = lx_remote->http_error_body.
      CATCH /iwbep/cx_gateway INTO DATA(lx_gateway).
        " Handle Exception
        lv_err_msg = lx_gateway->get_text( ).
      CATCH cx_web_http_client_error INTO DATA(lx_web_http_client_error).
        " Handle Exception
        RAISE SHORTDUMP lx_web_http_client_error.
        lv_err_msg = lx_web_http_client_error->get_text( ).
      CATCH cx_http_dest_provider_error INTO DATA(lx_provider_error).
        "handle exception
        lv_err_msg = lx_provider_error->get_text( ).
    ENDTRY.

    IF lv_err_msg IS INITIAL.
      <result>-status = 'Success'.
      <result>-criticality = 3. "Green
    ELSE.
      <result>-status = 'Failed'.
      <result>-criticality = 1. "Red
      <result>-response = lv_err_msg.
    ENDIF.

    MODIFY ENTITIES OF zr_trap_callodata IN LOCAL MODE
        ENTITY ZrTrapCallodata
        UPDATE FIELDS ( Purchaseorder status criticality response )
        WITH CORRESPONDING #( results )
        FAILED failed
        MAPPED mapped
        REPORTED reported.

  ENDMETHOD.

ENDCLASS.
