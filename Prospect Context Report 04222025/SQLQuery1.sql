-- Personal Details
With Personal_Details AS(
select 
contactId AS personId,
elcn_PrimaryID AS ID_NUMBER, 
elcn_SortName AS PREF_NAME_SORT,
fullname AS FULL_NAME,
EMailAddress1 AS EMAIL_ADDRESS
from ContactBase cb)
select pd.*--, pre.elcn_person2idname AS SPOUSE_GUID, pre.elcn_person2idname AS SPOUSE_NAME 
INTO #temp_personal_details
from Personal_Details pd
where FULL_NAME like '%greco%'

CREATE NONCLUSTERED INDEX IDX_tcd1 ON #temp_personal_details(personId)

-- TO DO: Get Spouse Advance ID and Constituent
select personId, pre.elcn_person2id AS Spouse_Guid, pre.elcn_person2idname AS Spouse_Name, fca.elcn_constituenttypeidname as Spouse_Constituent_Type
INTO #temp_spouse_details
from #temp_personal_details p
left join Filteredelcn_personalrelationship pre
on p.personId = pre.elcn_person1id
left join Filteredelcn_constituentaffiliation fca
on pre.elcn_person2id = fca.elcn_personid
where (pre.elcn_relationshiptype1idname = 'Spouse') --or pre.elcn_relationshiptype1idname is null)
and ( pre.elcn_person2idname is not null and pre.elcn_person2idname <> ' ')
and pre.statuscodename = 'Active'

CREATE NONCLUSTERED INDEX IDX_tcd2 ON #temp_spouse_details(personId)
select * from #temp_spouse_details

--Education
select  
fe.elcn_degreeyear AS DEG_YEAR,
fe.elcn_degreeidname AS DEG_CODE_DESC,
fe.elcn_collegeidname AS DEG_SCHOOL_CODE_DESC,
fe.elcn_departmentidname AS DEG_MAJOR1_DESC
from Filteredelcn_education fe
where elcn_personid = '0CF255E9-B005-4794-AD2F-382F371D6719'
order by fe.elcn_degreeyear 

--Business Info
select top 1 * from Filteredelcn_businessrelationship fbr
where elcn_personid = '0CF255E9-B005-4794-AD2F-382F371D6719'
and fbr.elcn_businessrelationshipstatusidname = 'Active'
and fbr.elcn_businessrelationshiptypeidname = 'Primary Employer'

--Business Address Info
select  top 1 
elcn_street1 AS BUS_STREET1,
elcn_city AS BUS_CITY,
elcn_stateprovinceidname AS BUS_STATE,
elcn_countryname AS BUS_COUNTRY,
elcn_postalcode AS BUS_ZIPCODE
from Filteredelcn_addressassociation addas
left join Filteredelcn_address fea -- connect with elcn_personid
on addas.elcn_addressid = fea.elcn_addressid
where elcn_personid = '0CF255E9-B005-4794-AD2F-382F371D6719'
and elcn_addressstatusidname = 'Current' 
and elcn_addresstypeidname = 'Business'

--Personal Address Info
select top 1
elcn_street1 AS BUS_STREET1,
elcn_city AS BUS_CITY,
elcn_stateprovinceidname AS BUS_STATE,
elcn_countryname AS BUS_COUNTRY,
elcn_postalcode AS BUS_ZIPCODE
from Filteredelcn_addressassociation addas
left join Filteredelcn_address fea -- connect with elcn_personid
on addas.elcn_addressid = fea.elcn_addressid
where elcn_personid = '0CF255E9-B005-4794-AD2F-382F371D6719'
and elcn_addressstatusidname = 'Current' 
and elcn_addresstypeidname = 'Home'

--Business Phone
select top 1
elcn_personid,
elcn_phonenumber AS BUS_PHONE
from Filteredelcn_phone
where elcn_personid = '0CF255E9-B005-4794-AD2F-382F371D6719'
and elcn_phonestatusidname = 'Active'
and elcn_phonetypename = 'Business'

--Home Phone
select top 1
elcn_personid,
elcn_phonenumber AS BUS_PHONE
from Filteredelcn_phone
where elcn_personid = '0CF255E9-B005-4794-AD2F-382F371D6719'
and elcn_phonestatusidname = 'Active'
and elcn_phonetypename = 'Home'

------**** DATA CONSOLIDATION****---------------

select pd.*
from #temp_personal_details pd
left join #temp_spouse_details sd
on pd.personId = sd.personId

drop table #temp_personal_details
drop table #temp_spouse_details

