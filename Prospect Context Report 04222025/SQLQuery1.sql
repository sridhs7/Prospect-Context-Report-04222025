-- Personal Details
With Personal_Details AS(
select 
contactId AS personId,
elcn_PrimaryID AS ID_NUMBER, 
elcn_SortName AS PREF_NAME_SORT,
fullname AS FULL_NAME,
EMailAddress1 AS EMAIL_ADDRESS
from ContactBase cb)
select pd.*, pre.elcn_person2idname AS SPOUSE_GUID, pre.elcn_person2idname AS SPOUSE_NAME 
from Personal_Details pd
left join  Filteredelcn_personalrelationship pre 
on pd.personId = pre.elcn_person1id
where (pre.elcn_relationshiptype1idname = 'Spouse' or pre.elcn_relationshiptype1idname is null)
and pd.personId = '0CF255E9-B005-4794-AD2F-382F371D6719'

-- TO DO: Get Spouse Advance ID and Constituent

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
select top 1000 * from Filteredelcn_businessrelationship fbr
where elcn_personid = '0CF255E9-B005-4794-AD2F-382F371D6719'
and fbr.elcn_businessrelationshipstatusidname = 'Active'
and fbr.elcn_businessrelationshiptypeidname = 'Primary Employer'