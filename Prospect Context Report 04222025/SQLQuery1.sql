-- Personal Details
select 
CRMAF_FilteredContact.contactId AS CRMAF_contactId,
CRMAF_FilteredContact.elcn_PrimaryID AS ID_NUMBER, 
CRMAF_FilteredContact.elcn_SortName AS PREF_NAME_SORT,
CRMAF_FilteredContact.fullname AS FULL_NAME,
CRMAF_FilteredContact.EMailAddress1 AS EMAIL_ADDRESS
INTO #temp_personal_details
from FilteredContact CRMAF_FilteredContact

CREATE NONCLUSTERED INDEX IDX_tcd1 ON #temp_personal_details(CRMAF_contactId)

--GET FILTERED PERSON IDs

select CRMAF_contactId
INTO #temp_personal_ids
from #temp_personal_details

CREATE NONCLUSTERED INDEX IDX_tcd_ids ON #temp_personal_ids(CRMAF_contactId)


-- TO DO: Get Spouse Advance ID and Constituent
SELECT 
    p.CRMAF_contactId, 
    pre.elcn_person2id AS Spouse_Guid, 
    pre.elcn_person2idname AS Spouse_Name, 
    fca.elcn_constituenttypeidname AS Spouse_Constituent_Type,
    cb.elcn_PrimaryID AS Spouse_ID_NUMBER  -- This is the new field
INTO #temp_spouse_details
FROM #temp_personal_details p
LEFT JOIN Filteredelcn_personalrelationship pre
    ON p.CRMAF_contactId = pre.elcn_person1id
LEFT JOIN Filteredelcn_constituentaffiliation fca
    ON pre.elcn_person2id = fca.elcn_personid
LEFT JOIN ContactBase cb
    ON pre.elcn_person2id = cb.contactId  -- Join to get spouse's elcn_PrimaryID
WHERE 
    pre.elcn_relationshiptype1idname = 'Spouse'
    AND pre.elcn_person2idname IS NOT NULL 
    AND pre.elcn_person2idname <> ' '
    AND pre.statuscodename = 'Active'

--select * from #temp_spouse_details

--Education

;WITH RankedEducation AS (
    SELECT 
        fe.elcn_personid,
        fe.elcn_degreeyear AS DEG_YEAR,
        fe.elcn_degreeidname AS DEG_CODE_DESC,
        fe.elcn_collegeidname AS DEG_SCHOOL_CODE_DESC,
        fe.elcn_departmentidname AS DEG_MAJOR1_DESC,
        ROW_NUMBER() OVER (
            PARTITION BY fe.elcn_personid 
            ORDER BY fe.elcn_degreeyear DESC
        ) AS rn
    FROM Filteredelcn_education fe
)
, PivotedEducation AS (
    SELECT 
        elcn_personid,

        -- Last Degree
        MAX(CASE WHEN rn = 1 THEN DEG_YEAR END) AS LAST_DEG_YEAR,
        MAX(CASE WHEN rn = 1 THEN DEG_CODE_DESC END) AS LAST_DEG_CODE_DESC,
        MAX(CASE WHEN rn = 1 THEN DEG_SCHOOL_CODE_DESC END) AS LAST_DEG_SCHOOL_CODE_DESC,
        MAX(CASE WHEN rn = 1 THEN DEG_MAJOR1_DESC END) AS LAST_DEG_MAJOR1_DESC,

        -- Second Last
        MAX(CASE WHEN rn = 2 THEN DEG_YEAR END) AS SECOND_LAST_DEG_YEAR,
        MAX(CASE WHEN rn = 2 THEN DEG_CODE_DESC END) AS SECOND_LAST_DEG_CODE_DESC,
        MAX(CASE WHEN rn = 2 THEN DEG_SCHOOL_CODE_DESC END) AS SECOND_LAST_SCHOOL_CODE_DESC,
        MAX(CASE WHEN rn = 2 THEN DEG_MAJOR1_DESC END) AS SECOND_LAST_DEG_MAJOR1_DESC,

        -- Third Last
        MAX(CASE WHEN rn = 3 THEN DEG_YEAR END) AS THIRD_LAST_DEG_YEAR,
        MAX(CASE WHEN rn = 3 THEN DEG_CODE_DESC END) AS THIRD_LAST_DEG_CODE_DESC,
        MAX(CASE WHEN rn = 3 THEN DEG_SCHOOL_CODE_DESC END) AS THIRD_LAST_SCHOOL_CODE_DESC,
        MAX(CASE WHEN rn = 3 THEN DEG_MAJOR1_DESC END) AS THIRD_LAST_DEG_MAJOR1_DESC,

        -- Fourth Last
        MAX(CASE WHEN rn = 4 THEN DEG_YEAR END) AS FOURTH_LAST_DEG_YEAR,
        MAX(CASE WHEN rn = 4 THEN DEG_CODE_DESC END) AS FOURTH_LAST_DEG_CODE_DESC,
        MAX(CASE WHEN rn = 4 THEN DEG_SCHOOL_CODE_DESC END) AS FOURTH_LAST_SCHOOL_CODE_DESC,
        MAX(CASE WHEN rn = 4 THEN DEG_MAJOR1_DESC END) AS FOURTH_LAST_DEG_MAJOR1_DESC

    FROM RankedEducation
    GROUP BY elcn_personid
)
select * 
INTO #temp_pivoted_education
from PivotedEducation
where PivotedEducation.elcn_personid in (select CRMAF_contactId from #temp_personal_ids);

CREATE NONCLUSTERED INDEX IDX_tcd3 ON #temp_pivoted_education(elcn_personid)



--Business Info
select top 1
fbr.elcn_fieldofworkidname, fbr.elcn_jobtitle, fbr.elcn_organizationidname, fbr.modifiedon, fbr.elcn_positionlevelidname
from Filteredelcn_businessrelationship fbr
where elcn_personid in (select CRMAF_contactId from #temp_personal_ids)
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
where elcn_personid in (select CRMAF_contactId from #temp_personal_ids)
and elcn_addressstatusidname = 'Current' 
and elcn_addresstypeidname = 'Business'
and statuscodename = 'Active'

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
where elcn_personid in (select CRMAF_contactId from #temp_personal_ids)
and elcn_addressstatusidname = 'Current' 
and elcn_addresstypeidname = 'Home'
and statuscodename = 'Active'

--Business Phone
select top 1
elcn_personid,
elcn_phonenumber AS BUS_PHONE
from Filteredelcn_phone
where elcn_personid in (select CRMAF_contactId from #temp_personal_ids)
and elcn_phonestatusidname = 'Active'
and elcn_phonetypename = 'Business'

--Home Phone
select top 1
elcn_personid,
elcn_phonenumber AS BUS_PHONE
from Filteredelcn_phone
where elcn_personid in (select CRMAF_contactId from #temp_personal_ids)
and elcn_phonestatusidname = 'Active'
and elcn_phonetypename = 'Home'

------**** DATA CONSOLIDATION****---------------

WITH SpouseRanked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY CRMAF_contactId 
            ORDER BY 
                CASE 
                    WHEN Spouse_Constituent_Type = 'Alumni' THEN 1 
                    ELSE 2 
                END
        ) AS rn
    FROM #temp_spouse_details
)
SELECT 
    pd.CRMAF_contactId,
    pd.ID_NUMBER,
    pd.PREF_NAME_SORT,
    pd.FULL_NAME,
    pd.EMAIL_ADDRESS,
    sr.Spouse_Guid,
    sr.Spouse_Name,
    sr.Spouse_Constituent_Type,
    sr.Spouse_ID_NUMBER,
    CASE 
        WHEN sr.Spouse_Constituent_Type = 'Alumni' THEN 'Y'
        ELSE 'N'
    END AS Is_Spouse_Alumni,
pe.*
FROM #temp_personal_details pd
LEFT JOIN SpouseRanked sr
    ON pd.CRMAF_contactId = sr.CRMAF_contactId
    AND sr.rn = 1
LEFT JOIN #temp_pivoted_education pe
ON pd.CRMAF_contactId = pe.elcn_personid



drop table #temp_personal_details
drop table #temp_spouse_details
drop table #temp_pivoted_education
drop table #temp_personal_ids
