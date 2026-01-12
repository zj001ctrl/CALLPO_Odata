@AccessControl.authorizationCheck: #MANDATORY
@Metadata.allowExtensions: true
@ObjectModel.sapObjectNodeType.name: 'ZTRAP_CALLODATA'
@EndUserText.label: '###GENERATED Core Data Service Entity'
define root view entity ZR_TRAP_CALLODATA
  as select from ztrap_callodata
{
  key uuid                  as UUID,
      purchaseorder         as Purchaseorder,
      response              as Response,
      status                as Status,
      criticality           as Criticality,
      @Semantics.user.createdBy: true
      created_by            as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at            as CreatedAt,
      @Semantics.user.localInstanceLastChangedBy: true
      local_last_changed_by as LocalLastChangedBy,
      @Semantics.systemDateTime.localInstanceLastChangedAt: true
      local_last_changed_at as LocalLastChangedAt,
      @Semantics.systemDateTime.lastChangedAt: true
      last_changed_at       as LastChangedAt
}
