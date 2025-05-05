With Personal_Details AS(
select 
contactId AS personId,
elcn_PrimaryID AS ID_NUMBER, 
elcn_SortName AS PREF_NAME_SORT,
fullname AS FULL_NAME
from ContactBase cb)
select pd.*, pre.elcn_person2idname AS SPOUSE_GUID, pre.elcn_person2idname AS SPOUSE_NAME 
from Personal_Details pd
left join  Filteredelcn_personalrelationship pre 
on pd.personId = pre.elcn_person1id
where (pre.elcn_relationshiptype1idname = 'Spouse' or pre.elcn_relationshiptype1idname is null)
and pd.personId = '0CF255E9-B005-4794-AD2F-382F371D6719'