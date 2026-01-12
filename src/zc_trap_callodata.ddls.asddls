@Metadata.allowExtensions: true
@Metadata.ignorePropagatedAnnotations: true
@EndUserText: {
  label: '###GENERATED Core Data Service Entity'
}
@ObjectModel: {
  sapObjectNodeType.name: 'ZTRAP_CALLODATA'
}
@AccessControl.authorizationCheck: #MANDATORY
define root view entity ZC_TRAP_CALLODATA
  provider contract transactional_query
  as projection on ZR_TRAP_CALLODATA
  association [1..1] to ZR_TRAP_CALLODATA as _BaseEntity on $projection.UUID = _BaseEntity.UUID
{
  key UUID,
      Purchaseorder,
      Response,
      Status,

      Criticality,
      @Semantics: {
        user.createdBy: true
      }
      CreatedBy,
      @Semantics: {
        systemDateTime.createdAt: true
      }
      CreatedAt,
      @Semantics: {
        user.localInstanceLastChangedBy: true
      }
      LocalLastChangedBy,
      @Semantics: {
        systemDateTime.localInstanceLastChangedAt: true
      }
      LocalLastChangedAt,
      @Semantics: {
        systemDateTime.lastChangedAt: true
      }
      LastChangedAt,
      _BaseEntity
}
