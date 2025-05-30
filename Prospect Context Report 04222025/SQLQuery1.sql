-- Personal Details
select 
CRMAF_FilteredContact.contactId AS CRMAF_contactId,
CRMAF_FilteredContact.elcn_PrimaryID AS ID_NUMBER, 
CRMAF_FilteredContact.elcn_SortName AS PREF_NAME_SORT,
CRMAF_FilteredContact.fullname AS FULL_NAME,
CRMAF_FilteredContact.EMailAddress1 AS EMAIL_ADDRESS,
CRMAF_FilteredContact.elcn_PrimaryProspectAssignment AS ASSIGNED_NAME,
CRMAF_FilteredContact.elcn_totalamountreceived AS LIFETIME_GIVING,
CRMAF_FilteredContact.elcn_lastcontributiondate AS LAST_GIFT_DT
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
;WITH RankedBusinessInfo AS (
  SELECT 
    fbr.elcn_personid,
    fbr.elcn_fieldofworkidname, 
    fbr.elcn_jobtitle, 
    fbr.elcn_organizationidname, 
    fbr.modifiedon, 
    fbr.elcn_positionlevelidname,
    ROW_NUMBER() OVER (
      PARTITION BY fbr.elcn_personid 
      ORDER BY fbr.modifiedon DESC
    ) AS rn
  FROM Filteredelcn_businessrelationship fbr
  WHERE fbr.elcn_personid IN (SELECT CRMAF_contactId FROM #temp_personal_ids)
    AND fbr.elcn_businessrelationshipstatusidname = 'Active'
    AND fbr.elcn_businessrelationshiptypeidname = 'Primary Employer'
)
SELECT * INTO #temp_business_info FROM RankedBusinessInfo WHERE rn = 1;


--Business Address Info
WITH RankedBusinessAddress AS (
  SELECT 
    addas.elcn_personid,
    fea.elcn_street1 AS BUS_STREET1,
    fea.elcn_city AS BUS_CITY,
    fea.elcn_stateprovinceidname AS BUS_STATE,
    fea.elcn_countryname AS BUS_COUNTRY,
    fea.elcn_postalcode AS BUS_ZIPCODE,
    ROW_NUMBER() OVER (
      PARTITION BY addas.elcn_personid 
      ORDER BY fea.modifiedon DESC
    ) AS rn
  FROM Filteredelcn_addressassociation addas
  LEFT JOIN Filteredelcn_address fea ON addas.elcn_addressid = fea.elcn_addressid
  WHERE addas.elcn_personid IN (SELECT CRMAF_contactId FROM #temp_personal_ids)
    AND addas.elcn_addressstatusidname = 'Current' 
    AND addas.elcn_addresstypeidname = 'Business'
    AND addas.statuscodename = 'Active'
)
SELECT * INTO #temp_business_address FROM RankedBusinessAddress WHERE rn = 1;


--Personal Address Info
WITH RankedPersonalAddress AS (
  SELECT 
    addas.elcn_personid,
    fea.elcn_street1 AS HOME_STREET1,
    fea.elcn_city AS HOME_CITY,
    fea.elcn_stateprovinceidname AS HOME_STATE,
    fea.elcn_countryname AS HOME_COUNTRY,
    fea.elcn_postalcode AS HOME_ZIPCODE,
    fea.modifiedon AS HOME_MOD_DT,
    ROW_NUMBER() OVER (
      PARTITION BY addas.elcn_personid 
      ORDER BY fea.modifiedon DESC
    ) AS rn
  FROM Filteredelcn_addressassociation addas
  LEFT JOIN Filteredelcn_address fea ON addas.elcn_addressid = fea.elcn_addressid
  WHERE addas.elcn_personid IN (SELECT CRMAF_contactId FROM #temp_personal_ids)
    AND addas.elcn_addressstatusidname = 'Current' 
    AND addas.elcn_addresstypeidname = 'Home'
    AND addas.statuscodename = 'Active'
)
SELECT * INTO #temp_home_address FROM RankedPersonalAddress WHERE rn = 1;


--Business Phone
WITH RankedBusinessPhone AS (
  SELECT 
    elcn_personid,
    elcn_phonenumber AS BUS_PHONE,
    ROW_NUMBER() OVER (
      PARTITION BY elcn_personid 
      ORDER BY modifiedon DESC
    ) AS rn
  FROM Filteredelcn_phone
  WHERE elcn_personid IN (SELECT CRMAF_contactId FROM #temp_personal_ids)
    AND elcn_phonestatusidname = 'Active'
    AND elcn_phonetypename = 'Business'
)
SELECT * INTO #temp_business_phone FROM RankedBusinessPhone WHERE rn = 1;


--Home Phone
WITH RankedHomePhone AS (
  SELECT 
    elcn_personid,
    elcn_phonenumber AS HOME_PHONE,
    ROW_NUMBER() OVER (
      PARTITION BY elcn_personid 
      ORDER BY modifiedon DESC
    ) AS rn
  FROM Filteredelcn_phone
  WHERE elcn_personid IN (SELECT CRMAF_contactId FROM #temp_personal_ids)
    AND elcn_phonestatusidname = 'Active'
    AND elcn_phonetypename = 'Home'
)
SELECT * INTO #temp_home_phone FROM RankedHomePhone WHERE rn = 1;


------**** DATA CONSOLIDATION****---------------

WITH SpouseRanked AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BY CRMAF_contactId 
            ORDER BY 
                CASE WHEN Spouse_Constituent_Type = 'Alumni' THEN 1 ELSE 2 END
        ) AS rn
    FROM #temp_spouse_details
)
SELECT 
    pd.CRMAF_contactId,
    pd.ID_NUMBER,
    pd.PREF_NAME_SORT,
    pd.FULL_NAME,
    pd.EMAIL_ADDRESS,
    pd.ASSIGNED_NAME,
    pd.LIFETIME_GIVING,
    pd.LAST_GIFT_DT,
    
    sr.Spouse_Guid,
    sr.Spouse_Name,
    sr.Spouse_Constituent_Type,
    sr.Spouse_ID_NUMBER,
    CASE WHEN sr.Spouse_Constituent_Type = 'Alumni' THEN 'Y' ELSE 'N' END AS Is_Spouse_Alumni,

    pe.*,
    bi.elcn_fieldofworkidname,
    bi.elcn_jobtitle,
    bi.elcn_organizationidname,
    bi.elcn_positionlevelidname,
    
    ba.BUS_STREET1, ba.BUS_CITY, ba.BUS_STATE, ba.BUS_COUNTRY, ba.BUS_ZIPCODE,
    ha.HOME_STREET1, ha.HOME_CITY, ha.HOME_STATE, ha.HOME_COUNTRY, ha.HOME_ZIPCODE, ha.HOME_MOD_DT,
    bp.BUS_PHONE,
    hp.HOME_PHONE

FROM #temp_personal_details pd
LEFT JOIN SpouseRanked sr ON pd.CRMAF_contactId = sr.CRMAF_contactId AND sr.rn = 1
LEFT JOIN #temp_pivoted_education pe ON pd.CRMAF_contactId = pe.elcn_personid
LEFT JOIN #temp_business_info bi ON pd.CRMAF_contactId = bi.elcn_personid
LEFT JOIN #temp_business_address ba ON pd.CRMAF_contactId = ba.elcn_personid
LEFT JOIN #temp_home_address ha ON pd.CRMAF_contactId = ha.elcn_personid
LEFT JOIN #temp_business_phone bp ON pd.CRMAF_contactId = bp.elcn_personid
LEFT JOIN #temp_home_phone hp ON pd.CRMAF_contactId = hp.elcn_personid;




drop table #temp_personal_details
drop table #temp_spouse_details
drop table #temp_pivoted_education
drop table #temp_personal_ids
