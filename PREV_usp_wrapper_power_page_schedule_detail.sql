USE [code]
GO

IF EXISTS (
		SELECT *
		FROM dbo.sysobjects
		WHERE id = object_id(N'[dbo].[usp_wrapper_power_page_schedule_detail]')
			AND OBJECTPROPERTY(id, N'IsProcedure') = 1
		)
	DROP PROCEDURE [dbo].[usp_wrapper_power_page_schedule_detail]
GO

CREATE PROCEDURE [dbo].[usp_wrapper_power_page_schedule_detail] (
 @customerid VARCHAR(10)
,@branchid VARCHAR(10)=NULL
)
AS
/******************************************************************************
** CREATED BY: JAYAPRH1
** CREATED ON: 10/23/2015
**
** PURPOSE   : Displays All The Master Contact Information Of The Customer
**
** ERROR HANDING:
** IF ALL STATEMENTS EXECUTE SUCCESSFULLY, A VALUE OF -1 WILL BE RETUNRED
** BY THE STORED PROCEDURE. IF A TRAPABLE ERROR OCCURS, A VALUE OF GREAT THAN
** ZERO WILL BE RETURNED. IF THE PROCEDURE IS TERMINATED BY SQL SERVER DUE TO
** ERRORS THAT ARE NOT TRAPPABLE, A VALUE OF ZERO WILL BE RETURNED.
**
** TEST CODE:
** EXEC code.dbo.usp_wrapper_power_page_schedule_detail @customerid='WE25715',@branchid='ASA'
** EXEC code.dbo.usp_wrapper_power_page_schedule_detail @customerid='JI11521',@branchid='BSB'
** EXEC code.dbo.usp_wrapper_power_page_schedule_detail @customerid='BH4593' ,@branchid='BSB'
** EXEC code.dbo.usp_wrapper_power_page_schedule_detail @customerid='FA19514',@branchid='BSB'
** EXEC code.dbo.usp_wrapper_power_page_schedule_detail @customerid='5J00001',@branchid='LSX'
** EXEC code.dbo.usp_wrapper_power_page_schedule_detail @customerid='5240006',@branchid='ASR'
** EXEC code.dbo.usp_wrapper_power_page_schedule_detail @customerid='AC18728',@branchid='BSB'
** EXEC code.dbo.usp_wrapper_power_page_schedule_detail @customerid='UR1940' ,@branchid='OSS'
** EXEC code.dbo.usp_wrapper_power_page_schedule_detail @customerid='GO11778',@branchid='RIS'
** EXEC code.dbo.usp_wrapper_power_page_schedule_detail @customerid='AU27990',@branchid='RIS'
** EXEC code.dbo.usp_wrapper_power_page_schedule_detail @customerid='US18411',@branchid='ILS'
** EXEC code.dbo.usp_wrapper_power_page_schedule_detail @customerid='SM07535',@branchid='RIS'
** EXEC code.dbo.usp_wrapper_power_page_schedule_detail @customerid='KA16903',@branchid='ISV'
** EXEC code.dbo.usp_wrapper_power_page_schedule_detail @customerid='VE17644',@branchid='ASA'
** UPDATE HISTORY:
** ----------------------------------------------------------------------------
** 10/23/2015   JAYAPRH1    Initial version
** 04/20/2016 	JAYAPRH1    Minor Change For LUBE Truck Type In SELECT Clause  
** 04/29/2015 	SANKARR1    Filtered void orders & changed join to pull all orders  
** 05/04/2016 	JAYAPRH1    DROP Statement Added. Corrected @weeknow Initialization  
** 05/04/2015 	PANDIAM1    Get only the records from [omcustomerservicemaster] where the inactivationdate is null as per the PBI #289193  
** 05/04/2016 	SANKARR1    Updated last and current service date logic   
** 05/05/2016 	JAYAPRH1    Merged The Code & Resolved Code Conflict Issues  
** 05/05/2016 	SANKARR1    Added condition to pull current week service for currentserviceweek field; Added customer service id  
** 05/06/2016 	JAYAPRH1 	Reverted Above Change(Becoz of incorrect DOT display).Added DISTINCT in Resultset. Alias Name Changed for ServiceID  
** 05/13/2016 	JAYAPRH1 	Added MachineAssetTag (#Asset No)  
** 05/20/2016 	JAYAPRH1 	Added COALESCE Statement For CSGNumber  
** 07/01/2016 	SHANMUT1 	Created Username added (ref # 294608)  
** 07/05/2016 	SHANMUT1 	Completed dt taken for completed orders (ref Bug #294607)   
** 07/29/2016   JAYAPRH1    Changed reference.dbo.business_unit_attributes(TABLE) to reference.dbo.business_unit_attribute_view(VIEW)
						    Included OM Serv Type Cd.Excluded Part No(s) 10255 & 10256.Exclude om_serv_type_cd ['C']
** 09/26/2016	JAYAPRH1	New Additional CSG Logic Implemented  
** 10/18/2016	JAYAPRH1	Asset Link Concept Included.COALESCE Added
** 01/04/2017	SHANMUT1	Past 2 weeks calculation aded 
** 02/02/2017	SHANMUT1	route_name,stop# included in the output 
** 04/03/2017   SHANMUT1	actv_indcr validated for vehicle alignment and order alignment 
** 04/24/2017	KUMARS3		profile_no included in the output 
** 04/25/2017	PANDIAM1	profile_expired status added
** 05/16/2017   SHANMUT1	Department id column included 
** 06/22/2017	SHANMUT1	Part washer identifier included 
** 07/07/2017	SHANMUT1	creator email address included 
** 07/25/2017	SHANMUT1	Exclude Part numbers functionality removed 
** 07/28/2017	SHANMUT1	Last 3 weeks data filtered 
** 07/31/2017	SHANMUT1	Customer services fetch issue fix 
** 08/17/2017	SHANMUT1	Created by use issue fix 
** 08/18/2017	PANDIAM1	Add profile description from [cwt] 
** 08/30/2017	SANKARR1	Increased the profile description length
** 09/19/2017	SHANMUT1	336963- Bug Fix
** 10/06/2017	SHANMUT1	Added IsOnServicePlan column + Profile status validated from choice.dbo.porofil_vendor
** 03/11/2017	KUMARS3		Usage Frequency column included
** 04/03/2018	KUMARS3		Exclude AR Order Details
** 04/05/2018	SHANMUT1	Profile vendor table vendorid='ch' validation added 
** 04/23/2018	SHANMUT1	AR order restriction issue fix 
** 06/14/2018	SHANMUT1	Add DIY column 
** 09/27/2018	SHANMUT1	PBI 375553 Implementation (Serial Number inclusion)
** 11/15/2018	KUMARS3		Adding PullDate and placementdate validation for MachineAssetTag#
** 11/30/2018	SHANMUT1	INC986921 fixed
** 01/03/2019	KUMARS3		Adding associated service waste profile validation
** 01/21/2019	KUMARS3		Revert SP to Production code as per Raj request. 
** 04/25/2019   JOTHILS2	Added condition to retrieve assets where pull date is null 
** 03/23/2020				PBI 428268 Sreehari Naik Meghavath	"Profile related changes"
** 11/10/2020	BERMAE1		Bug 423741 Logic to exclude associated services (VAC, UMO waste) that have expired profiles. 
******************************************************************************/
BEGIN
	SET NOCOUNT ON

			/*** Declaration Section ***/
			DECLARE @err	   INT  
			DECLARE @yearnow   INT
			DECLARE @weeknow   INT
			DECLARE @dt		   DATETIME 
			DECLARE @target_cd VARCHAR(10)
			DECLARE @source_cd VARCHAR(10)    
			DECLARE @weekSundayStDate DATETIME
			DECLARE @om_serv_type_tbl TABLE  (om_serv_type_cd CHAR(1))

			
			INSERT INTO @om_serv_type_tbl (om_serv_type_cd)
			SELECT value FROM code.dbo.fn_split((SELECT value 
			FROM [reference].[dbo].[app_config_settings] acs 
			WHERE acs.[app_name]='PowerPage' AND [key]='ExcludeServiceTypeCodes'),',') 


			CREATE TABLE #tmp_service_summary (  
												customerserviceid	BIGINT
											   ,customerid			VARCHAR(10)
											   ,serviceorderid		BIGINT
											   ,serviceid			INT
											   ,profile_no			VARCHAR(15)
											   ,term				INT  
											   ,scheduledweek		INT
											   ,ScheduledYear		INT
											   ,NextScheduledWeek	INT
											   ,nextscheduledyear	INT
											   ,lastserviceweek		INT										  
											   ,lastservicedate		DATETIME
											   ,AssociatedBranchID	VARCHAR(50)
											   ,dept				VARCHAR(50)
											   ,recordstatus		VARCHAR(50)  
											   ,zip					VARCHAR(40)
											   ,is_adhoc_indcr		BIT DEFAULT (0)
											   ,MachineAssetTag		VARCHAR(50)	
											   ,branchid			VARCHAR(10)              
											   ,csgnumber			VARCHAR(50)
											   ,creatd_by			VARCHAR(200)
											   ,completed_dt		DATETIME   
											   ,om_serv_type_cd		CHAR(1)	
											  ,hierarchy_value		VARCHAR(25)  
											  ,asset_part_no		VARCHAR(50)	
											  ,asset_part_name		VARCHAR(40)
											  ,asset_part_dscrpn	VARCHAR(256)
											   ,serviceorderbranch  VARCHAR(10)
											   ,ActualScheduleDate  DATETIME
											   ,profile_status VARCHAR(1)
											   ,email_address		VARCHAR(70)
											   ,placement_dt		DATETIME
											   ,profile_desc VARCHAR(200)
											   ,IsOnServicePlan		BIT 
											   ,UsageFrequency		VARCHAR(100)
											   ,IsDIY int
											   ,SerialNumber		VARCHAR(50)
											   ,custmr_co_cd		VARCHAR(50)
											   ,IsVendorService     BIT
									         )							
			
			SET @dt = GETDATE()
			SET @dt= DATEADD(WEEK,-3,@dt)
			SET @yearnow =(SELECT YEAR(@dt))
			SET @weeknow =DATEPART(WK,@dt)-1

			SELECT @target_cd =(SELECT TOP (1) COALESCE(target_cd,'')    
				 FROM reference.dbo.dupe_account_targets dat     
				 WHERE dat.dupe_cd=@CustomerId AND dat.dupe_xprtn_dt >@dt
				 ORDER BY dupe_account_target_id DESC)    
    
			SELECT @source_cd =(SELECT TOP (1) COALESCE(dupe_cd,'')    
				 FROM reference.dbo.dupe_account_targets dat     
				 WHERE dat.target_cd=@CustomerId AND dat.dupe_xprtn_dt >@dt  
				 ORDER BY dupe_account_target_id DESC) 
			

			
			IF (@weeknow=1)
			BEGIN
					SET @weeknow=53
					SET @yearnow=@yearnow -1
			END
			
						
			
			INSERT INTO #tmp_service_summary   (  
						  						    customerserviceid
												   ,customerid		
						  						   ,serviceorderid			
						  						   ,serviceid	
						  						   ,profile_no			
						  						   ,term					
						  						   ,scheduledweek			
						  						   ,ScheduledYear			
						  						   ,NextScheduledWeek		
						  						   ,nextscheduledyear		
						  						   ,lastserviceweek			
						  						   ,lastservicedate			
						  						   ,AssociatedBranchID
												   ,dept		
						  						   ,recordstatus			
						  						   ,zip	
												   ,is_adhoc_indcr	
												   ,MachineAssetTag	
												   ,branchid
												   ,csgnumber
												   ,creatd_by	
												   ,completed_dt
												   ,om_serv_type_cd				 			  						  										 		
													 ,hierarchy_value    
													 ,asset_part_no
													 ,asset_part_name
													 ,asset_part_dscrpn                          
												   ,serviceorderbranch
												   ,ActualScheduleDate	
												   ,profile_status			
												   ,email_address 	
												   ,placement_dt
												   ,profile_desc	
												   ,IsOnServicePlan	
												   ,UsageFrequency
												   ,IsDIY
												   ,SerialNumber
												   ,custmr_co_cd
												   ,IsVendorService
						  					   )							

   SELECT    DISTINCT  
							 omcsm.CustomerServiceID
							,omcsm.customerid
							,omsom.serviceorderid    
							,omcsm.serviceid  
							,omcsm.WasteProfileID							
							,omcsm.term AS service_term    															
							,omsom.scheduledweek    
							,omsom.ScheduledYear    
							,omcsm.NextScheduledWeek    
							,omcsm.nextscheduledyear   
							--,DATEPART(WK,omcsm.LastServiceDate) AS lastserviceweek    
							,CASE WHEN omsom.RecordStatus = 'COMPLETE' THEN DATEPART(ISO_WEEK,omcsm.LastServiceDate) ELSE  DATEPART(ISO_WEEK,omcsm.LastServiceDate)   END  AS lastserviceweek              
							,omcsm.LastServiceDate  AS lastservicedate 					  							 
							,omcsm.AssociatedBranchID  
							,omcsm.Department
							,omsom.RecordStatus  
							,ca.zip
							,(CASE WHEN omsom.ordersource='ServiceRequest' THEN 1 ELSE 0 END) AS is_adhoc_indcr
							,COALESCE(omm.MachineAssetTag,mat.machine_asset_tag)
							,omsom.branchid
							,omsom.csgnumber
							,em.first_name + ' ' + em.last_name AS creatd_by 
							,omsom.ClosedDateTime 
							,pm.om_serv_type_cd 
						    ,ph.hierarchy_value  
						    ,INTAB.asset_part_no
						    ,INTAB.asset_part_name
						    ,INTAB.asset_part_dscrpn
							,omsom.BranchID 
							,omsom.ActualScheduleDate 		
							,CASE WHEN COALESCE(pv.[status],wp.prflStaCd)  IN ('E') OR COALESCE(pv.expiration_date,@dt) < @dt OR COALESCE(asps.expired,'')='E' THEN 'E' ELSE 'A' END profile_status
							,ee.email_address
							,omcsm.placementdate
							,wp.prflMtrlName  	
							,omcsm.IsOnServicePlan
							,CASE WHEN omcsm.UsageFrequency	= '52' THEN 'Once Per Year'
								  WHEN omcsm.UsageFrequency	= '26' THEN 'Twice Per Year'
								  WHEN omcsm.UsageFrequency	= '12' THEN 'Four Times Per Year'
							 END	AS UsageFrequency
							,CASE WHEN (pm.part_name like '%DIY%' or pm.part_name like '%DO-IT-YOURSELF%') and pm.actv_indcr=1 THEN 1 ELSE 0 END as IsDIY
							,omm.MachineSerialNumber AS SerialNumber
							,cl.custmr_co_cd	
							,omcsm.IsVendorService			
   FROM  [skomdb].[dbo].[omcustomerservicemaster] omcsm    
			LEFT JOIN [skomdb].[dbo].[omserviceorderdetails] omsod   
				ON omcsm.serviceid=omsod.serviceid AND omcsm.customerserviceid=omsod.customerserviceid	AND omsod.IsActive=1  
			LEFT JOIN [cwt].[dbo].[profile] wp   
				ON omcsm.WasteProfileID=wp.prflNum 
				LEFT JOIN choice.dbo.profil_vendor pv  ON omcsm.WasteProfileID = pv.vendor_profil_no AND omcsm.CustomerID = pv.genrtr
				AND pv.vendor_id='CH'
			LEFT JOIN [skomdb].[dbo].[omserviceordermaster] omsom   
				ON omsod.serviceorderid = omsom.serviceorderid   AND ((omsom.ScheduledYear >= @yearnow AND omsom.ScheduledWeek >= @weeknow) 
				OR 	(omsom.ScheduledYear > @yearnow )) AND COALESCE(omsom.VoidReasonId, 0) = 0	
				AND COALESCE(omsom.OMServiceOrderTypeLovID,-1) <> 2 --Excluding AR Orders		
			LEFT JOIN reference.dbo.emplye_master em  ON omsom.CreateUser = em.usrnam 
			LEFT JOIN reference.dbo.emplye_email ee  ON em.emplye_id= ee.emplye_id AND ee.email_address_type = 'BUSN' AND ee.actv_indcr =1 
			LEFT JOIN order_mgmt.pricing.part_master pm 
				ON pm.part_no =  omcsm.ServiceID 
			LEFT JOIN order_mgmt.pricing.part_hierarchy ph   
				ON ph.part_hierarchy_id=pm.part_hierarchy_id  
			INNER JOIN reference.dbo.company_addr ca     
				ON omcsm.customerid=ca.co_cd AND addr_type='CORP'   
			LEFT JOIN reference.dbo.company_link cl     
				ON omcsm.customerid=cl.genrtr_co_cd 
			LEFT JOIN skomdb.dbo.OMMachine omm 
				ON omm.MachineID=omcsm.MachineID
		    OUTER APPLY (SELECT TOP 1    aa.ServiceID   AS asset_part_no
										,p.part_name    AS asset_part_name
										,p.part_dscrpn  AS asset_part_dscrpn
								FROM skomdb.dbo.OMCustomerServiceMasterAssetAssociation aa 
								INNER JOIN skomdb.dbo.OMMachine m 
								ON aa.MachineID=m.machineid AND aa.actv_indcr=1
								INNER JOIN order_mgmt.pricing.part_master p 
								ON p.part_no=aa.serviceID								
								WHERE aa.customerserviceid=omcsm.customerserviceid AND aa.PullDate IS NULL --AND aa.serviceid=omcsm.serviceid 
								ORDER BY aa.ServiceID
						) INTAB
			OUTER APPLY (SELECT TOP 1 CASE WHEN (COALESCE(p.[status],'') IN ('E') OR COALESCE(p.expiration_date,@dt) < @dt ) THEN 'E' ELSE 'A' END as expired
								FROM skomdb.dbo.OMCustomerServiceMasterServiceAssociation sa 
								INNER JOIN choice.dbo.profil_vendor p 
									ON sa.wasteprofileid = p.vendor_profil_no 
									AND P.genrtr = omcsm.customerid AND p.vendor_id='CH'
								WHERE sa.customerserviceid=omcsm.customerserviceid 
								AND sa.actv_indcr = 1 
								ORDER BY CASE WHEN (COALESCE(p.[status],'') IN ('E') OR COALESCE(p.expiration_date,@dt) < @dt ) THEN 2 ELSE 1 END
								-- If any non-expired associated profile exists, prefer that one. Otherwise, if any expired profile exists, return expired status.
						) asps	
			OUTER APPLY (
						   SELECT TOP 1   m.MachineAssetTag AS machine_asset_tag
						   FROM skomdb.dbo.OMCustomerServiceMasterAssetAssociation aa 								
						   INNER JOIN skomdb.dbo.OMMachine m 
						   ON aa.MachineID=m.machineid AND aa.actv_indcr=1 AND m.MachineAssetTag IS NOT NULL 
						   WHERE aa.customerserviceid=omcsm.customerserviceid AND aa.PullDate IS NULL ORDER BY m.MachineAssetTag) mat		
		    WHERE omcsm.CustomerID IN (@CustomerId,@target_cd,@source_cd)    
						AND omcsm.associatedbranchid =@branchid 
						AND omcsm.servicestatus='ACTIVE' AND omcsm.InactivationDate IS NULL 
							
				
			CREATE TABLE #tmp_summary_detail  
			(  
					ActualScheduleDate  DATETIME  
					,ServiceOrderID	    INT  
					,ServiceID          INT  
					,RecordStatus		VARCHAR(50)  
					,RowOrder			INT  
					,creatd_by          VARCHAR(200)  
					,completed_dt       DATETIME  
					,email_address	    VARCHAR(100)
			)

		    SET @weekSundayStDate = DATEADD(week, datediff(Day,0, getdate()-7)/7,0)-1
					
		    INSERT INTO #tmp_summary_detail  (   
											   ActualScheduleDate
											  ,ServiceOrderID
											  ,ServiceID
											  ,RecordStatus
											  ,RowOrder
											  ,creatd_by
											  ,completed_dt
											  ,email_address
											 ) 


			SELECT   osm.ActualScheduleDate 
					,osm.ServiceOrderID  
					,osd.ServiceID 
					,osm.RecordStatus
					,ROW_NUMBER() OVER (PARTITION BY osd.ServiceID ORDER BY osm.ActualScheduleDate ASC) 
					,COALESCE(em.first_name + ' ' + em.last_name,osm.CreateUser) AS creatd_by
					,osm.ClosedDateTime
					,ee.email_address
			FROM [skomdb].[dbo].[omserviceordermaster] osm   
  			LEFT JOIN reference.dbo.emplye_master em  ON osm.CreateUser = em.usrnam
			LEFT JOIN reference.dbo.emplye_email ee  on ee.emplye_id = em.emplye_id  AND ee.email_address_type = 'BUSN' AND ee.actv_indcr =1 
			LEFT JOIN  [skomdb].[dbo].[OMServiceOrderDetails] osd 
			ON osm.ServiceOrderID = osd.ServiceOrderID
			WHERE customerid IN(@customerId,@target_Cd,@source_cd)  AND osm.RecordStatus <> 'COMPLETE' AND osm.ActualScheduleDate > = @weekSundayStDate
			UNION All
			SELECT   osm.ActualScheduleDate 
					,osm.ServiceOrderID  
					,osd.ServiceID 
					,osm.RecordStatus
					,ROW_NUMBER() OVER (PARTITION BY osd.ServiceID ORDER BY osm.ActualScheduleDate DESC) 
					,COALESCE(em.first_name + ' ' + em.last_name,osm.CreateUser) AS creatd_by
					,osm.ClosedDateTime
					,ee.email_address 
			FROM [skomdb].[dbo].[omserviceordermaster] osm  
			LEFT JOIN reference.dbo.emplye_master em  ON osm.CreateUser = em.usrnam 
			LEFT JOIN reference.dbo.emplye_email ee  on ee.emplye_id = em.emplye_id AND ee.email_address_type = 'BUSN' AND ee.actv_indcr =1 
			LEFT JOIN  [skomdb].[dbo].[OMServiceOrderDetails] osd 
			ON osm.ServiceOrderID = osd.ServiceOrderID
			WHERE customerid IN(@customerId,@target_Cd,@source_cd)  AND osm.RecordStatus = 'COMPLETE'
   --AND COALESCE(osm.VoidReasonId, 0) = 0  
			
			
	   
			SELECT DISTINCT  tss.customerid  
			                ,COALESCE(omtt.trucktypename,
							NULLIF(PARSENAME(REPLACE(skomdb.dbo.udf_GetCSGTypeByProductHierarchyNumberByBranch(tss.hierarchy_value,tss.zip ,tss.associatedbranchid),'-','.'),2),'')) AS customer_service_type
							,tss.customerserviceid
							,tss.serviceorderid    
							,tss.serviceid AS serviceid  
							,tss.profile_no  
							,pm.part_name  AS servicename   														
							,tss.term AS service_term 							   
							,COALESCE(OMCSG.CsgName  
								,NULLIF(skomdb.dbo.udf_GetCSGTypeByProductHierarchyNumberByBranch(tss.hierarchy_value,tss.zip,tss.associatedbranchid),'')  
								,NULLIF(skomdb.dbo.GetDefaultCSGLongName(COALESCE(zcsm.CSGNo,'0'), zcsm.AssociatedBranchID, BUA.attribute_cd),'')  
								,skomdb.dbo.GetDefaultCSGLongName(COALESCE(tss.CSGNumber,'0'), tss.BranchId,BUA.attribute_cd))  AS CSGName     
							,BUA.attribute_id
							,BD.Dept									
							,CASE WHEN tss.recordstatus = 'COMPLETE' THEN DATEPART(ISO_WEEK,COALESCE(tss.completed_dt,ct.completed_dt)) ELSE  tss.scheduledweek   END  AS scheduledweek
							,CASE WHEN tss.recordstatus = 'COMPLETE' THEN DATEPART(YEAR,COALESCE(tss.completed_dt,ct.completed_dt)) ELSE  tss.ScheduledYear   END  AS ScheduledYear
							--,COALESCE(DATEPART(WK,CurrSvcDt.ActualScheduleDate),tss.scheduledweek) AS currentscheduledweek
							--,COALESCE(DATEPART(YEAR,CurrSvcDt.ActualScheduleDate),tss.scheduledweek) AS currentscheduledyear
							,tss.NextScheduledWeek    
							,tss.nextscheduledyear   
						   --,COALESCE(tss.lastserviceweek,DATEPART(WK,ct.ActualScheduleDate)) AS lastserviceweek 
						    ,CASE WHEN tss.recordstatus = 'COMPLETE' THEN COALESCE(tss.lastserviceweek,DATEPART(ISO_WEEK,ct.ActualScheduleDate)) ELSE  COALESCE(tss.lastserviceweek,DATEPART(WK,ct.ActualScheduleDate))   END  AS lastserviceweek
						    --,COALESCE(tss.lastservicedate,ct.ActualScheduleDate)  AS lastservicedate 
							,tss.lastservicedate AS lastservicedate
							,CONVERT(VARCHAR(8),pm.part_no) AS partnumber    
							,tss.AssociatedBranchID  AS AssociatedBranchID  
							,tss.RecordStatus  												
							,CurrSvcDt.ActualScheduleDate AS LatestServiceDate
							,tss.is_adhoc_indcr
							,tss.MachineAssetTag
							,tss.creatd_by as adhoc_CreatedUsername
							,tss.om_serv_type_cd 
						   ,tss.asset_part_no
						   ,tss.asset_part_name
						   ,tss.asset_part_dscrpn  
							,CASE WHEN pml.part_material_group_id IS NOT NULL THEN va.remarks ELSE NULL END AS route_name 
							,CASE WHEN pml.part_material_group_id IS NOT NULL THEN oa.truck_stop ELSE NULL END  as stop_number
							,tss.serviceorderbranch 
							,tss.ActualScheduleDate 	
							,tss.profile_status			
							,tss.dept AS DepartMent 
							--,CASE WHEN tss.hierarchy_value LIKE '1000%' THEN 1 ELSE CASE WHEN tss.hierarchy_value LIKE '7000%' THEN 1 ELSE  0 END  END AS is_part_washer 
							,CASE WHEN tss.hierarchy_value LIKE '1000%' OR tss.hierarchy_value LIKE '2000%' OR tss.hierarchy_value LIKE '7000%' OR tss.hierarchy_value LIKE '4000%'
										OR tss.hierarchy_value LIKE '5000%' OR tss.hierarchy_value LIKE '5100%' OR tss.hierarchy_value LIKE '6100%'
								  THEN 1 ELSE 0 END AS is_part_washer
							,tss.email_address AS email_address
							,tss.placement_dt 
							,tss.profile_desc
							,tss.IsOnServicePlan
							,tss.UsageFrequency
							,tss.IsDIY
							,tss.SerialNumber
							,tss.custmr_co_cd
							,tss.IsVendorService							
			FROM  #tmp_service_summary tss        			
			LEFT JOIN #tmp_summary_detail ct  ON ct.ServiceID  = tss.ServiceID and ct.RowORDER = 1  AND ct.RecordStatus = 'COMPLETE'   
			LEFT JOIN order_mgmt.dbo.order_alignment oa  ON tss.ServiceOrderID = oa.order_no AND oa.actv_indcr =1 
			LEFT JOIN order_mgmt.dbo.vhcle_alignment va  ON oa.vhcle_alignment_id = va.vhcle_alignment_id AND va.actv_indcr =1 
			--LEFT JOIN #tmp_summary_detail ct1  ON ct1.ServiceID  = tss.ServiceID and ct1.RowORDER = 1  AND ct1.RecordStatus <> 'COMPLETE'  
			INNER JOIN order_mgmt.pricing.part_master pm     
				ON tss.serviceid=pm.part_no    AND pm.actv_indcr=1  					
			OUTER APPLY (SELECT TOP 1 part_material_group_id FROM order_mgmt.pricing.part_material_group_link pl 
							WHERE pm.part_master_id = pl.part_master_id AND pl.part_material_group_id IN (74,75,76,83) ORDER BY part_material_group_id) pml
			LEFT JOIN skomdb.dbo.ZRPT_CustomerServiceMasterwithCSGType zcsm 
				--ON zcsm.CustomerID=tss.CustomerID AND zcsm.serviceid=tss.serviceid AND zcsm.associatedbranchid=tss.associatedbranchid
				ON zcsm.CustomerServiceID=tss.CustomerServiceID 
			LEFT JOIN skomdb.dbo.OMCSGMapping AS omcsg   
				ON omcsg.PostalCode =tss.zip
				   AND omcsg.CSGType = zcsm.CSGType  
				   AND omcsg.BranchCode = zcsm.AssociatedBranchID 
			LEFT JOIN [skomdb].[dbo].OMTruckTypeCSGType omttc    
				ON zcsm.csgtype=omttc.csgtype  
			LEFT JOIN skomdb.dbo.omtrucktype omtt     
				ON omttc.trucktype=omtt.trucktype  				   
			LEFT JOIN reference.dbo.branch_dept BD   
				ON BD.branch =  tss.AssociatedBranchID  
			LEFT JOIN reference.dbo.Business_unit_attribute_view BUA   
				ON BD.business_unit_ar = BUA.business_unit  	
			OUTER APPLY (SELECT TOP 1 ActualScheduleDate FROM #tmp_summary_detail WHERE ServiceID  = tss.ServiceID AND
			RecordStatus <> 'COMPLETE' AND ActualScheduleDate > =   DATEADD(WEEK, DATEDIFF(DAY,0, GETDATE())/7,0)-1 ORDER BY ServiceID) CurrSvcDt   
			WHERE NOT EXISTS (SELECT TOP 1 1 
									   FROM  @om_serv_type_tbl ostt 
									   WHERE ostt.om_serv_type_cd=tss.om_serv_type_cd ORDER BY ostt.om_serv_type_cd)
			ORDER BY tss.serviceorderid
					,tss.serviceid
					,scheduledweek
					,ScheduledYear     
			  
			SELECT @err = @@ERROR

			IF @err <> 0
			BEGIN
				DROP TABLE #tmp_service_summary   
				DROP TABLE #tmp_summary_detail
				RETURN @err
			END		  
			
			DROP TABLE #tmp_service_summary   
			DROP TABLE #tmp_summary_detail
END
GO

GRANT EXECUTE
	ON [dbo].[usp_wrapper_power_page_schedule_detail]
	TO [app_WIN]
GO