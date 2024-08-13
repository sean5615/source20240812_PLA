<%/*
----------------------------------------------------------------------------------
File Name		: pla015m_01m1.jsp
Author			: leon
Description		: PLA015M_實習選課預排 - 處理邏輯頁面
Modification Log	:

Vers		Date       	By            	Notes
--------------	--------------	--------------	----------------------------------
0.0.1		096/08/20	leon    	Code Generate Create
----------------------------------------------------------------------------------
*/%>
<%@ page contentType="text/html; charset=UTF-8" pageEncoding="MS950"%>
<%@ include file="/utility/header.jsp"%>
<%@ include file="/utility/modulepageinit.jsp"%>
<%@ page import="java.util.Vector"%>
<%@ page import="java.util.Hashtable"%>
<%@ page import="com.acer.log.MyLogger"%>
<%@ page import="com.nou.aut.AUTCONNECT"%>
<%@ page import="com.acer.db.DBManager"%>
<%@ page import="com.acer.db.DBAccess"%>
<%@ page import="com.nou.pla.dao.*"%>
<%@ page import="com.nou.reg.dao.*"%>
<%@ page import="com.nou.pla.bo.*"%>
<%@ page import="com.nou.reg.bo.*"%>
<%@ page import="java.util.*"%>
<%@page import="com.nou.UtilityX"%>


<%!
/** 處理查詢 Grid 資料 */
public void doQuery(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{

//     STEP1 取得所有中心
//     STEP2 取得本學預定開設網路班科目清單
//     STEP3 取得各中心過瀘出來打算開網路班的科目人數
//     STEP4 組成要SHOW出的結構

    Connection conn=null;
    StringBuffer sql = new StringBuffer();

	try
	{
        int NUM1=99;
        if(!Utility.nullToSpace(requestMap.get("NUM1")).equals("")) {
           NUM1=Integer.parseInt(requestMap.get("NUM1").toString());
        }

		conn	=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", "0"));
        Vector result = new Vector();        //回傳的vt
        Vector vtCENTER_CODE = new Vector();        //X軸 各中心清單
        Vector vtCRSNO = new Vector();        //Y軸 科目清單
        Hashtable rowHtST_NUM = null;               //X與Y 之間的值 (各科目下的各中心無解人次有多少)
        Hashtable rowHtX = null;                    //X TEMP HT
        Hashtable rowHtY = null;                    //Y TEMP HT
        Hashtable resultHT = new Hashtable();                  //組出HTML的 TEMP HT        conn       =    dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));
        System.out.println("====STEP1 取得所有中心，並組第一行的TITLE");
        //STEP1 取得所有中心
        sql.append(" SELECT A.CENTER_ABBRNAME, B.AYEAR,B.SMS,A.CENTER_ABRCODE,A.CENTER_NAME,CASE WHEN SUM(DECODE(NVL(LOCK1,'X'),'X','0','1'))=0 THEN 'N' "+
	   			   " WHEN SUM(DECODE(NVL(LOCK1,'X'),'X','0','1'))>SUM(CASE WHEN B.LOCK1='Y' THEN '1' ELSE '0' END) THEN 'N' "+
	   			   " WHEN SUM(DECODE(NVL(LOCK1,'X'),'X','0','1'))=SUM(CASE WHEN B.LOCK1='Y' THEN '1' ELSE '0' END) THEN 'Y' ELSE 'N' END AS YN  "+
	   			   " FROM SYST002 A  "+
	   			   " LEFT JOIN PLAT002 B ON A.CENTER_ABRCODE=B.CENTER_ABRCODE AND B.CMPS_KIND IN ('1','2') AND B.AYEAR='"+Utility.nullToSpace(requestMap.get("AYEAR"))+"' AND B.SMS='"+Utility.nullToSpace(requestMap.get("SMS"))+"' "+
	   			   " AND B.NETWK_CLASS = '" + Utility.nullToSpace(requestMap.get("NETWK_CLASS")) + "' " +
 				   " GROUP BY A.CENTER_ABBRNAME, B.AYEAR,B.SMS,A.CENTER_ABRCODE,A.CENTER_NAME "+
	   			   "  ORDER BY A.CENTER_ABRCODE ");

        DBResult rs = null;
        rs = dbManager.getSimpleResultSet(conn);
        rs.open();

        System.out.println(sql.toString());
        rs.executeQuery(sql.toString());

        String tmpStr="";
        String YN="Y";
        while (rs.next()) {
            rowHtX = new Hashtable();
            tmpStr+="<TD resize='on' nowrap>"+rs.getString("CENTER_ABBRNAME")+rs.getString("YN")+"</TD>";
            if(rs.getString("YN").equals("N"))YN="N";
            for (int i = 1; i <= rs.getColumnCount(); i++)
            {
                rowHtX.put(rs.getColumnName(i), rs.getString(i));
            }
            vtCENTER_CODE.add(rowHtX);
        }
        YN = "<input type=hidden name='YN' id='YN' value='"+YN+"'>";
        resultHT.put("TD",tmpStr+YN);
        result.add(resultHT);
        rs.close();

        String nexWorkClassName = requestMap.get("NETWK_CLASS_NAME").toString().substring(0,4);
        
        if(sql.length() > 0)sql.delete(0, sql.length());        
        String step2Sql = 
        	"select SUBSTR(d.CRS_NAME,0,"+NUM1+") AS CCRSNO, d.CRS_NAME, A.CRSNO, A.MASTER_CLASS_CODE, nvl(f.CLASS_NUM,'0') as CLASS_NUM \n"+
			"from regt007 a \n"+
			"join stut003 b on a.STNO=b.STNO \n"+
			"join syst002 c on b.CENTER_CODE=c.CENTER_CODE \n"+
			"join cout002 d on a.crsno=d.crsno \n"+
			"join syst001 e on e.kind='NETWK_CLASS' AND e.CODE_NAME=a.MASTER_CLASS_CODE "+
			"left join plat033 f on a.ayear=f.ayear and a.sms=f.sms and a.crsno=f.crsno and f.netwk_class=e.CODE \n"+
			"where \n"+
			"    a.AYEAR='"+requestMap.get("AYEAR")+"' \n"+
			"and a.sms='"+requestMap.get("SMS")+"' \n"+
			"and a.MASTER_CLASS_CODE='"+ nexWorkClassName +"' \n"+
			"and a.UNQUAL_TAKE_MK='N' \n"+
			"and a.UNTAKECRS_MK='N' \n"+
			"and a.PAYMENT_STATUS>'1' \n"+
		//	"and exists (select 1 from pert004 d where a.ayear=d.ayear and a.SMS=d.SMS and a.CRSNO=d.CRSNO) \n"+
			"group by a.CRSNO, d.crs_name, A.MASTER_CLASS_CODE, f.CLASS_NUM \n"+
			"order by a.crsno";
        
        rs = null;
        rs = dbManager.getSimpleResultSet(conn);
        rs.open();
        rs.executeQuery(step2Sql);
        rowHtST_NUM = new Hashtable();
        while (rs.next()) {
            rowHtY = new Hashtable();
            for (int i = 1; i <= rs.getColumnCount(); i++)
                rowHtY.put(rs.getColumnName(i), rs.getString(i));
            vtCRSNO.add(rowHtY);            
        }
        rs.close();
		
        if(sql.length() > 0)sql.delete(0, sql.length());
        System.out.println("====STEP3 取得各中心過瀘出來打算開網路班的科目人數");
        //STEP3 取得各中心過瀘出來打算開網路班的科目人數
        /*
        String step3Sql = 
        	"SELECT A.CRSNO||A.CENTER_ABRCODE AS G_KEY,A.CENTER_ABRCODE,A.CRSNO,SUM(A.TAKE_NUM) AS ST_NUM \n"+
        	"FROM PLAT009 A \n"+
        	"JOIN PLAT002 B ON A.AYEAR=B.AYEAR AND A.SMS=B.SMS AND A.CENTER_ABRCODE=B.CENTER_ABRCODE AND A.CMPS_CODE=B.CMPS_CODE AND B.NETWK_CLASS='"+requestMap.get("NETWK_CLASS")+"' \n"+
        	"WHERE \n"+
        	"	 A.CLASS_KIND='2' \n"+
        	"AND A.AYEAR='"+requestMap.get("AYEAR")+"' \n"+
        	"AND A.SMS='"+requestMap.get("SMS")+"' \n"+        	
        	"GROUP BY A.CRSNO||A.CENTER_ABRCODE, A.CENTER_ABRCODE, A.CRSNO \n"+
        	"ORDER BY A.CRSNO||A.CENTER_ABRCODE \n";
        */
        
        String step3Sql = 
        	"select a.CRSNO||c.CENTER_ABRCODE as G_KEY, A.CRSNO, A.MASTER_CLASS_CODE, COUNT(1) AS ST_NUM \n"+
			"from regt007 a \n"+
			"join stut003 b on a.STNO=b.STNO \n"+
			"join syst002 c on b.CENTER_CODE=c.CENTER_CODE \n"+
			"where \n"+
			"    a.AYEAR='"+requestMap.get("AYEAR")+"' \n"+
			"and a.sms='"+requestMap.get("SMS")+"' \n"+
			"and a.MASTER_CLASS_CODE='" + nexWorkClassName + "' \n"+
			"and a.UNQUAL_TAKE_MK='N' \n"+
			"and a.UNTAKECRS_MK='N' \n"+
			"and a.PAYMENT_STATUS>'1' \n"+
		//	"and exists (select 1 from pert004 d where a.ayear=d.ayear and a.SMS=d.SMS and a.CRSNO=d.CRSNO) \n"+
			"group by a.CRSNO, c.CENTER_ABRCODE, A.MASTER_CLASS_CODE \n"+
			"order by a.crsno";
        
        	
        rs = null;
        rs = dbManager.getSimpleResultSet(conn);
        rs.open();
        rs.executeQuery(step3Sql);
        rowHtST_NUM = new Hashtable();
        while (rs.next()) {
            rowHtST_NUM.put(rs.getString("G_KEY"), rs.getString("ST_NUM"));         
        }
        rs.close();

        System.out.println("====STEP4 組成要SHOW出的結構");
        //STEP4 組成要SHOW出的結構
        String TD="";
        int num=0;
        for (int ii=0;ii<vtCRSNO.size();ii++)
        {
            resultHT = new Hashtable();
            rowHtY = new Hashtable();
            rowHtY = (Hashtable)vtCRSNO.get(ii);
			String CEN_ARY="";
            TD="";
            num=0;
            String crsnoStuNum = ""; // 為了編排網路班用,因邊排網路班速度太慢,因此每科每個中心的人數資訊在這取得
            for (int iii=0;iii<vtCENTER_CODE.size();iii++)
            {
                rowHtX = new Hashtable();
                rowHtX = (Hashtable)vtCENTER_CODE.get(iii);
                tmpStr=rowHtY.get("CRSNO").toString()+rowHtX.get("CENTER_ABRCODE").toString();
                if(rowHtST_NUM.containsKey(tmpStr)){
                    TD+="<TD align=center>"+rowHtST_NUM.get(tmpStr).toString()+"</TD>";
                    num+= Integer.parseInt(rowHtST_NUM.get(tmpStr).toString());
					if(CEN_ARY.indexOf(rowHtX.get("CENTER_ABRCODE").toString()) == -1)
						CEN_ARY += ";'"+rowHtX.get("CENTER_ABRCODE").toString()+"'";
					
					crsnoStuNum+=(crsnoStuNum.equals("")?"":"_")+Integer.parseInt(rowHtST_NUM.get(tmpStr).toString());
                }else{
                    TD+="<TD align=center>0</TD>";
                    crsnoStuNum+=(crsnoStuNum.equals("")?"":"_")+"0";
                }
            }
            
            // 放入總計人數
            crsnoStuNum+="_"+num;
            
            resultHT.put("AYEAR",Utility.nullToSpace(requestMap.get("AYEAR")));
            resultHT.put("SMS",Utility.nullToSpace(requestMap.get("SMS")));
            resultHT.put("CRSNO",rowHtY.get("CRSNO").toString());
            resultHT.put("CCRSNO",rowHtY.get("CCRSNO").toString());
			resultHT.put("CRS_NAME",rowHtY.get("CRS_NAME").toString());
            resultHT.put("ST_COUNT",String.valueOf(num));
            resultHT.put("TD",TD);		
            resultHT.put("CRSNO_ALL_STU_NUM",crsnoStuNum); // 為了編排網路班用,因邊排網路班速度太慢,因此每科每個中心的人數資訊在這取得
            resultHT.put("MASTER_CLASS_CODE",rowHtY.get("MASTER_CLASS_CODE"));
			if(CEN_ARY.length()>0)
				CEN_ARY = CEN_ARY.substring(1);
			resultHT.put("CEN_ARY",CEN_ARY);
			resultHT.put("CLASS_NUM",rowHtY.get("CLASS_NUM"));
			
            result.add(resultHT);
        }

        out.println(DataToJson.vtToJson(result));

	}
	catch (Exception ex)
	{
		ex.printStackTrace();
		throw ex;
	}
	finally
	{
		dbManager.close();
	}

}

/** 處理查詢 Grid 資料 */
public void doQuery_Old(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{

//     STEP1 取得所有中心
//     STEP2 取得本學預定開設網路班科目清單
//     STEP3 取得各中心過瀘出來打算開網路班的科目人數
//     STEP4 組成要SHOW出的結構

    Connection conn=null;
    StringBuffer sql = new StringBuffer();

	try
	{
        int NUM1=99;
        if(!Utility.nullToSpace(requestMap.get("NUM1")).equals("")) {
           NUM1=Integer.parseInt(requestMap.get("NUM1").toString());
        }

		conn	=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", "0"));
        Vector result = new Vector();        //回傳的vt
        Vector vtCENTER_CODE = new Vector();        //X軸 各中心清單
        Vector vtCRSNO = new Vector();        //Y軸 科目清單
        Hashtable rowHtST_NUM = null;               //X與Y 之間的值 (各科目下的各中心無解人次有多少)
        Hashtable rowHtX = null;                    //X TEMP HT
        Hashtable rowHtY = null;                    //Y TEMP HT
        Hashtable resultHT = new Hashtable();                  //組出HTML的 TEMP HT        conn       =    dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));
        System.out.println("====STEP1 取得所有中心，並組第一行的TITLE");
        //STEP1 取得所有中心
        sql.append(" SELECT A.CENTER_ABBRNAME, B.AYEAR,B.SMS,A.CENTER_ABRCODE,A.CENTER_NAME, B.CMPS_CODE, CASE WHEN SUM(DECODE(NVL(LOCK1,'X'),'X','0','1'))=0 THEN 'N' "+
	   			   " WHEN SUM(DECODE(NVL(LOCK1,'X'),'X','0','1'))>SUM(CASE WHEN B.LOCK1='Y' THEN '1' ELSE '0' END) THEN 'N' "+
	   			   " WHEN SUM(DECODE(NVL(LOCK1,'X'),'X','0','1'))=SUM(CASE WHEN B.LOCK1='Y' THEN '1' ELSE '0' END) THEN 'Y' ELSE 'N' END AS YN  "+
	   			   " FROM SYST002 A  "+
	   			   " LEFT JOIN PLAT002 B ON A.CENTER_ABRCODE=B.CENTER_ABRCODE AND B.CMPS_KIND IN ('1','2') AND B.AYEAR='"+Utility.nullToSpace(requestMap.get("AYEAR"))+"' AND B.SMS='"+Utility.nullToSpace(requestMap.get("SMS"))+"' "+
	   			   " GROUP BY A.CENTER_ABBRNAME, B.AYEAR,B.SMS,A.CENTER_ABRCODE,A.CENTER_NAME, B.CMPS_CODE "+
	   			   "  ORDER BY A.CENTER_ABRCODE ");

        DBResult rs = null;
        rs = dbManager.getSimpleResultSet(conn);
        rs.open();

        System.out.println(sql.toString());
        rs.executeQuery(sql.toString());

        String tmpStr="";
        String YN="Y";
        while (rs.next()) {
            rowHtX = new Hashtable();
            tmpStr+="<TD resize='on' nowrap>"+rs.getString("CENTER_ABBRNAME")+rs.getString("YN")+"</TD>";
            if(rs.getString("YN").equals("N"))YN="N";
            for (int i = 1; i <= rs.getColumnCount(); i++)
            {
                rowHtX.put(rs.getColumnName(i), rs.getString(i));
            }
            vtCENTER_CODE.add(rowHtX);
        }
        YN = "<input type=hidden name='YN' id='YN' value='"+YN+"'>";
        resultHT.put("TD",tmpStr+YN);
        result.add(resultHT);
        rs.close();

        if(sql.length() > 0)sql.delete(0, sql.length());
        System.out.println("====STEP2 取得本學預定開設網路班科目清單");
        //STEP2 取得本學預定開設網路班科目清單
        sql.append(" SELECT DISTINCT A.CRSNO,SUBSTR(B.CRS_NAME,0,"+NUM1+") AS CCRSNO, B.CRS_NAME FROM PERT004 A JOIN COUT002 B ON A.CRSNO=B.CRSNO WHERE 0=0 ");

        if(!Utility.nullToSpace(requestMap.get("AYEAR")).equals("")) {
            sql.append(" AND AYEAR = '" + Utility.nullToSpace(requestMap.get("AYEAR")) + "' ");
        }
        if(!Utility.nullToSpace(requestMap.get("SMS")).equals("")) {
            sql.append(" AND SMS = '" + Utility.nullToSpace(requestMap.get("SMS")) + "' ");
        }
        sql.append(" ORDER BY A.CRSNO ");

        rs = null;
        rs = dbManager.getSimpleResultSet(conn);
        rs.open();
        rs.executeQuery(sql.toString());
        while (rs.next()) {
            rowHtY = new Hashtable();
            for (int i = 1; i <= rs.getColumnCount(); i++)
                rowHtY.put(rs.getColumnName(i), rs.getString(i));
            vtCRSNO.add(rowHtY);
        }
        rs.close();

        if(sql.length() > 0)sql.delete(0, sql.length());
        System.out.println("====STEP3 取得各中心過瀘出來打算開網路班的科目人數");
        //STEP3 取得各中心過瀘出來打算開網路班的科目人數
        /*
        String step3Sql = 
        	"SELECT A.CRSNO||A.CENTER_ABRCODE AS G_KEY,A.CENTER_ABRCODE,A.CRSNO,SUM(A.TAKE_NUM) AS ST_NUM \n"+
        	"FROM PLAT009 A \n"+
        	"JOIN PLAT002 B ON A.AYEAR=B.AYEAR AND A.SMS=B.SMS AND A.CENTER_ABRCODE=B.CENTER_ABRCODE AND A.CMPS_CODE=B.CMPS_CODE AND B.NETWK_CLASS='"+requestMap.get("NETWK_CLASS")+"' \n"+
        	"WHERE \n"+
        	"	 A.CLASS_KIND='2' \n"+
        	"AND A.AYEAR='"+requestMap.get("AYEAR")+"' \n"+
        	"AND A.SMS='"+requestMap.get("SMS")+"' \n"+        	
        	"GROUP BY A.CRSNO||A.CENTER_ABRCODE, A.CENTER_ABRCODE, A.CRSNO \n"+
        	"ORDER BY A.CRSNO||A.CENTER_ABRCODE \n";
        */
        
        String step3Sql = 
        	"select a.CRSNO||c.CENTER_ABRCODE||a.TUT_CMPS_CODE as G_KEY, A.CRSNO, COUNT(1) AS ST_NUM \n"+
			"from regt007 a \n"+
			"join stut003 b on a.STNO=b.STNO \n"+
			"join syst002 c on b.CENTER_CODE=c.CENTER_CODE \n"+
			"where \n"+
			"    a.AYEAR='"+requestMap.get("AYEAR")+"' \n"+
			"and a.sms='"+requestMap.get("SMS")+"' \n"+
			"and a.MASTER_CLASS_CODE='"+requestMap.get("NETWK_CLASS_NAME").toString().substring(0,4)+"' \n"+
			"and a.UNQUAL_TAKE_MK='N' \n"+
			"and a.UNTAKECRS_MK='N' \n"+
			"and a.PAYMENT_STATUS>'1' \n"+
			"and exists (select 1 from pert004 d where a.ayear=d.ayear and a.SMS=d.SMS and a.CRSNO=d.CRSNO) \n"+
			"group by a.CRSNO, c.CENTER_ABRCODE, a.TUT_CMPS_CODE \n";
        
        	
        rs = null;
        rs = dbManager.getSimpleResultSet(conn);
        rs.open();
        rs.executeQuery(step3Sql);
        rowHtST_NUM = new Hashtable();
        while (rs.next()) {
            rowHtST_NUM.put(rs.getString("G_KEY"), rs.getString("ST_NUM"));
        }
        rs.close();

        System.out.println("====STEP4 組成要SHOW出的結構");
        //STEP4 組成要SHOW出的結構
        String TD="";
        int num=0;
        for (int ii=0;ii<vtCRSNO.size();ii++)
        {
            resultHT = new Hashtable();
            rowHtY = new Hashtable();
            rowHtY = (Hashtable)vtCRSNO.get(ii);
			String CEN_ARY="";
            TD="";
            num=0;
            String crsnoStuNum = ""; // 為了編排網路班用,因邊排網路班速度太慢,因此每科每個中心的人數資訊在這取得
            for (int iii=0;iii<vtCENTER_CODE.size();iii++)
            {
                rowHtX = new Hashtable();
                rowHtX = (Hashtable)vtCENTER_CODE.get(iii);
                tmpStr=rowHtY.get("CRSNO").toString()+rowHtX.get("CENTER_ABRCODE").toString();
                if(rowHtST_NUM.containsKey(tmpStr)){
                    TD+="<TD align=center>"+rowHtST_NUM.get(tmpStr).toString()+"</TD>";
                    num+= Integer.parseInt(rowHtST_NUM.get(tmpStr).toString());
					if(CEN_ARY.indexOf(rowHtX.get("CENTER_ABRCODE").toString()) == -1)
						CEN_ARY += ";'"+rowHtX.get("CENTER_ABRCODE").toString()+"'";
					
					crsnoStuNum+=(crsnoStuNum.equals("")?"":"_")+Integer.parseInt(rowHtST_NUM.get(tmpStr).toString());
                }else{
                    TD+="<TD align=center>0</TD>";
                    crsnoStuNum+=(crsnoStuNum.equals("")?"":"_")+"0";
                }
            }
            
            // 放入總計人數
            crsnoStuNum+="_"+num;
            
            resultHT.put("AYEAR",Utility.nullToSpace(requestMap.get("AYEAR")));
            resultHT.put("SMS",Utility.nullToSpace(requestMap.get("SMS")));
            resultHT.put("CRSNO",rowHtY.get("CRSNO").toString());
            resultHT.put("CCRSNO",rowHtY.get("CCRSNO").toString());
			resultHT.put("CRS_NAME",rowHtY.get("CRS_NAME").toString());
            resultHT.put("ST_COUNT",String.valueOf(num));
            resultHT.put("TD",TD);		
            resultHT.put("CRSNO_ALL_STU_NUM",crsnoStuNum); // 為了編排網路班用,因邊排網路班速度太慢,因此每科每個中心的人數資訊在這取得
			if(CEN_ARY.length()>0)
				CEN_ARY = CEN_ARY.substring(1);
			resultHT.put("CEN_ARY",CEN_ARY);
            result.add(resultHT);
        }


        out.println(DataToJson.vtToJson(result));

	}
	catch (Exception ex)
	{
		throw ex;
	}
	finally
	{
		dbManager.close();
	}

}

public void doQueryV2(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{
	try
	{
		Connection conn = dbManager.getConnection(AUTCONNECT.mapConnect("PLA", "0"));
		
		String sql = 
			"SELECT DISTINCT a.class_kind, f.CRSNO, f.CRS_NAME, a.CENTER_ABRCODE, d.CENTER_ABBRNAME, a.CMPS_CODE, e.CMPS_NAME, c.MASTER_CLASS_CODE, c.TUT_CLASS_CODE, c.ASS_CLASS_CODE ,G.Z_STNUM \n"+ 
			"FROM PLAT012 a  \n"+
			"JOIN REGT007 c ON a.AYEAR=c.AYEAR AND a.SMS=c.SMS AND a.CRSNO=c.CRSNO AND c.TUT_CLASS_CODE=a.CLASS_CODE AND c.MASTER_CLASS_CODE='"+requestMap.get("NETWK_CLASS_NAME").toString().substring(0,4)+"' \n"+ 
			"JOIN (SELECT C1.AYEAR,C1.SMS,C1.CRSNO,C1.TUT_CLASS_CODE,COUNT(1) AS Z_STNUM FROM  REGT007 C1 WHERE C1.AYEAR='"+requestMap.get("AYEAR")+"' AND C1.SMS='"+requestMap.get("SMS")+"' AND  C1.MASTER_CLASS_CODE='"+requestMap.get("NETWK_CLASS_NAME").toString().substring(0,4)+"' GROUP BY C1.AYEAR,C1.SMS,C1.CRSNO,C1.TUT_CLASS_CODE) G ON A.AYEAR=G.AYEAR AND A.SMS=C.SMS AND A.CRSNO=G.CRSNO AND G.TUT_CLASS_CODE=A.CLASS_CODE \n"+
			"JOIN SYST002 d ON a.CENTER_ABRCODE=d.CENTER_ABRCODE  \n"+
			"JOIN PLAT002 e ON a.AYEAR=e.AYEAR AND a.SMS=e.SMS AND a.CENTER_ABRCODE=e.CENTER_ABRCODE AND a.CMPS_CODE=e.CMPS_CODE \n"+ 
			"JOIN COUT002 f ON a.CRSNO=f.CRSNO \n"+ 
			"WHERE "+
			"	 a.AYEAR='"+requestMap.get("AYEAR")+"' \n"+
			"AND a.SMS='"+requestMap.get("SMS")+"' \n"+
			(Utility.nullToSpace(requestMap.get("CENTER_CODE")).equals("")?"":"AND d.CENTER_CODE='"+requestMap.get("CENTER_CODE")+"' \n")+
			(Utility.nullToSpace(requestMap.get("CRSNO")).equals("")?"":"AND a.CRSNO='"+requestMap.get("CRSNO")+"' \n")+
			"ORDER BY a.CENTER_ABRCODE, a.CMPS_CODE, f.CRSNO, c.TUT_CLASS_CODE  \n";		

        DBResult rs = null;
        rs = dbManager.getSimpleResultSet(conn);
        rs.open();
        rs.executeQuery(sql.toString());
        out.println(DataToJson.rsToJson(rs));
	}
	catch (Exception ex)
	{
		throw ex;
	}
	finally
	{
		dbManager.close();
	}

}

/** 處理新增存檔 */
public void doAdd(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{
	try
	{
		Connection	conn	=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));
    	/** 處理新增動作 */
    	PLAT017DAO	PLAT017	=	new PLAT017DAO(dbManager, conn, requestMap, session);
    	PLAT017.setUPD_MK("1");
    	PLAT017.insert();

    	/** Commit Transaction */
    	dbManager.commit();

		out.println(DataToJson.successJson());
	}
	catch (Exception ex)
	{
		/** Rollback Transaction */
		dbManager.rollback();

		throw ex;
	}
	finally
	{
		dbManager.close();
	}
}

/** 修改帶出資料 */
public void doQueryEdit(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{
	Connection	conn	=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));
	PLAT012DAO	PLAT012	=	new PLAT012DAO(dbManager, conn);
	PLAT012.setResultColumn("AYEAR, SMS, CLASS_CODE, CLASS_KIND, CENTER_ABRCODE, CMPS_CODE, CLSSRM_CODE, SEGMENTS_CODE, SWEEK, CRSNO, SECTION_CODE, TCH_IDNO, ROWSTAMP");
	PLAT012.setAYEAR(Utility.dbStr(requestMap.get("AYEAR")));
	PLAT012.setSMS(Utility.dbStr(requestMap.get("SMS")));
	PLAT012.setCLASS_CODE(Utility.dbStr(requestMap.get("CLASS_CODE")));

	DBResult	rs	=	PLAT012.query();

	out.println(DataToJson.rsToJson (rs));

	dbManager.close();
}
/** 習實預排 */
public void doPRESETLABCRSNO(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{

    Connection conn=null;
	try
	{
        conn       =    dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));
        PLAPRESETLABCRSNO  plat017  =    new PLAPRESETLABCRSNO();

        String result = plat017.getPLAPRESETLABCRSNO(requestMap, dbManager);

		out.println(DataToJson.successJson(result));

	}
	catch (Exception ex)
	{
		throw ex;
	}
	finally
	{
		dbManager.close();
	}

}
/** 載入學生志願 
public void doLOADLABWISH(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{

    Connection conn=null;
	try
	{
        conn       =    dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));
        PLADOLOADLABWISH  plat017  =    new PLADOLOADLABWISH();

        String result = plat017.doLOADLABWISH(requestMap);

		out.println(DataToJson.successJson(result));

	}
	catch (Exception ex)
	{
		throw ex;
	}
	finally
	{
		dbManager.close();
	}
}
*/
/** 修改存檔 */
public void doModify(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{
	try
	{
		Connection	conn	=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));

		/** 修改條件 */
		String	condition	=	"AYEAR		=	'" + Utility.dbStr(requestMap.get("AYEAR"))+ "' AND " +
						"SMS		=	'" + Utility.dbStr(requestMap.get("SMS"))+ "' AND " +
						"CLASS_CODE	=	'" + Utility.dbStr(requestMap.get("CLASS_CODE"))+ "' AND " +
						"ROWSTAMP	=	'" + Utility.dbStr(requestMap.get("ROWSTAMP")) + "' ";

		/** 處理修改動作 */
		PLAT012DAO	PLAT012	=	new PLAT012DAO(dbManager, conn, requestMap, session);
		int	updateCount	=	PLAT012.update(condition);

		/** Commit Transaction */
		dbManager.commit();

		if (updateCount == 0)
			out.println(DataToJson.faileJson("此筆資料已被異動過, <br>請重新查詢修改!!"));
		else
			out.println(DataToJson.successJson());
	}
	catch (Exception ex)
	{
		/** Rollback Transaction */
		dbManager.rollback();

		throw ex;
	}
	finally
	{
		dbManager.close();
	}
}

/** 執行網路編班-中心學生數拆班_全中心 */
public void doDelete(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{
    DBManager dbmanager=null;
    DBResult rs = null;
	try
	{
		Connection	conn		=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));

		String netwkClassName = requestMap.get("NETWK_CLASS_NAME").toString().substring(0,4); // 網路班原班代號 ex:@0@0
		
		String thirdClassCode = "Z";
		String fourClassCode = "";
		if("@0@0".equals(netwkClassName)) {
			fourClassCode = "0";
		} else if("@0@1".equals(netwkClassName)) {
			fourClassCode = "1";
		} else if("@0@2".equals(netwkClassName)) {
			fourClassCode = "2";
		}
		
		
        String[]    AYEAR   =   Utility.split(requestMap.get("AYEAR").toString(), ",");
        String[]    SMS     =   Utility.split(requestMap.get("SMS").toString(), ",");
		
		// STEP1. 刪除PLAT012這各科目網路班的資料
		PLAT012DAO	PLAT012	=	new PLAT012DAO(dbManager, conn, requestMap, session);		
		PLAT012.delete( " AYEAR='"+AYEAR[0]+"' AND SMS='"+SMS[0]+"' AND (SUBSTR(CLASS_CODE,3,2)='"+thirdClassCode+""+fourClassCode +"' OR CLASS_CODE='"+netwkClassName+"') " );
		
		// 原本是一科開一班,現在有可能一開開多班,因此改成用下面的方式
		// STEP2:取得每科要分成幾班,如為0表示不開班
		PLAT033DAO plat033 = new PLAT033DAO(dbManager, conn);
		plat033.setResultColumn("CRSNO, CLASS_NUM");
		plat033.setWhere(
			"	 AYEAR='"+AYEAR[0]+"' "+
			"AND SMS='"+SMS[0]+"' "+
			"AND NETWK_CLASS='"+requestMap.get("NETWK_CLASS")+"' "+
			"AND CLASS_NUM>0 "
		);
		rs = plat033.query();
		
		
		// 一次處理一科
		while(rs.next()){
			String crsno = rs.getString("CRSNO");
			int classNum = rs.getInt("CLASS_NUM");
			
			String sql = 
					"SELECT a.STNO "+ 
					"FROM regt007 a \n"+
					"JOIN stut003 b on a.STNO=b.stno \n"+
					"JOIN SYST002 C ON B.CENTER_CODE=C.CENTER_CODE \n"+
					"WHERE A.AYEAR='"+AYEAR[0]+"' \n"+ 
					"AND A.SMS='"+SMS[0]+"' \n"+
					"AND A.CRSNO='"+crsno+"' \n"+
					"AND A.MASTER_CLASS_CODE='"+netwkClassName+"' \n"+
					"AND A.TUT_CMPS_CODE IS NOT NULL "+
					"AND A.UNQUAL_TAKE_MK = 'N' "+
					"AND A.UNTAKECRS_MK = 'N' "+
					"AND A.PAYMENT_STATUS != '1' "+
					"ORDER BY B.CENTER_CODE";
							
			Vector st = new Vector();
			Vector vtSt = UtilityX.getvtData(dbManager, conn, sql);
			int cNum = (vtSt.size() / classNum) + ((vtSt.size() % classNum != 0) ? 1: 0);
			System.out.println(crsno+"X"+vtSt.size() +"X"+ classNum + "X" +cNum);
			StringBuffer d = new StringBuffer();
			for (int i = 1; i <= vtSt.size(); i++){		
				String stno = Utility.nullToSpace(((Hashtable)vtSt.get(i-1)).get("STNO")) ;
				d.append(stno).append(",");
				if(i % cNum == 0 ){
					if(d.length() > 0) {
			            d.delete(d.length()-1, d.length());
			        }
					st.add(d.toString());
					d = new StringBuffer();
				} 
			}	
			
			if(d.length()!=0){
				if(d.length() > 0) {
		            d.delete(d.length()-1, d.length());
		        }
				st.add(d.toString());
			}
			
			for (int i = 1; i <= st.size(); i++){		
				String stnoStr =  Utility.nullToSpace(st.get(i-1));
				//System.out.println(stnoStr);
				// STEP4 輸入新的校本部班級代碼，面授班 
				// 每個中心寫入一筆CLASS_KIND=1(一般面授)--FOR 考試  但仍需新增CLASS_KIND=2(網路)
				PLAT012DAO plat012 = new PLAT012DAO(dbManager, conn);
				String insertPlat012_2 = 
			            "INSERT INTO PLAT012(AYEAR, SMS, CLASS_CODE, CENTER_ABRCODE, CMPS_CODE, SWEEK, CLASS_KIND, CRSNO, SEGMENT_CODE, SECTION_CODE, TCH_IDNO, CLSSRM_CODE, CLS_YN, UPD_USER_ID, UPD_DATE, UPD_TIME, UPD_MK, ROWSTAMP) \n"+
			            "SELECT DISTINCT A.AYEAR ,A.SMS, C.CENTER_ABRCODE||SUBSTR(A.TUT_CMPS_CODE,1,1)||'"+thirdClassCode + fourClassCode +Utility.fillZero(i+"",2)+"' AS CLASS_CODE, C.CENTER_ABRCODE, A.TUT_CMPS_CODE AS CMPS_CODE, \n"+ 
						"    '1' AS SWEEK, '1' AS CLASS_KIND , A.CRSNO, '1' AS SEGMENT_CODE, '1' AS SECTION_CODE, '', '"+netwkClassName+"' AS CLSSRM_CODE, 'Y' AS CLS_YN, \n"+  
						"    '"+(String)session.getAttribute("USER_ID")+"','"+Utility.dbStr(DateUtil.getNowDate())+"' ,'"+Utility.dbStr(DateUtil.getNowTimeS())+"','1','"+ Utility.dbStr(DateUtil.getNowTimeMs()) +"' \n"+  
						"FROM regt007 a \n"+
						"JOIN stut003 b on a.STNO=b.stno \n"+
						"JOIN SYST002 C ON B.CENTER_CODE=C.CENTER_CODE \n"+
						"WHERE \n"+
						"     A.AYEAR='"+AYEAR[0]+"' \n"+ 
						"AND A.SMS='"+SMS[0]+"' \n"+
						"AND A.CRSNO='"+crsno+"' \n"+
						"AND A.MASTER_CLASS_CODE='"+netwkClassName+"' \n"+
						"AND A.STNO IN ('"+Utility.replace(stnoStr, ",", "','")+"') \n"; 			            
				plat012.execute(insertPlat012_2);
				

				// STEP5  新增CLASS_KIND=2(網路)
				plat012 = new PLAT012DAO(dbManager, conn);
				String insertPlat012_3 = 	        
			            "INSERT INTO PLAT012(AYEAR, SMS, CLASS_CODE, CENTER_ABRCODE, CMPS_CODE, SWEEK, CLASS_KIND, CRSNO, SEGMENT_CODE, SECTION_CODE, TCH_IDNO, CLSSRM_CODE, CLS_YN, UPD_USER_ID, UPD_DATE, UPD_TIME, UPD_MK, ROWSTAMP) "+
			            "SELECT DISTINCT A.AYEAR ,A.SMS, 'ZZ"+thirdClassCode + fourClassCode +Utility.fillZero(i+"",2)+"' AS CLASS_CODE, C.CENTER_ABRCODE, A.TUT_CMPS_CODE AS CMPS_CODE, \n"+ 
						"    '1' AS SWEEK, '2' AS CLASS_KIND , A.CRSNO, '1' AS SEGMENT_CODE, '1' AS SECTION_CODE, '', '"+netwkClassName+"' AS CLSSRM_CODE, 'Y' AS CLS_YN, \n"+  
						"    '"+(String)session.getAttribute("USER_ID")+"','"+Utility.dbStr(DateUtil.getNowDate())+"' ,'"+Utility.dbStr(DateUtil.getNowTimeS())+"','1','"+ Utility.dbStr(DateUtil.getNowTimeMs()) +"' \n"+  
						"FROM regt007 a \n"+
						"JOIN stut003 b on a.STNO=b.stno \n"+
						"JOIN SYST002 C ON B.CENTER_CODE=C.CENTER_CODE \n"+
						"WHERE \n"+
						"     A.AYEAR='"+AYEAR[0]+"' \n"+ 
						"AND A.SMS='"+SMS[0]+"' \n"+
						"AND A.CRSNO='"+crsno+"' \n"+
						"AND a.MASTER_CLASS_CODE='"+netwkClassName+"' \n"+
						"AND A.STNO IN ('"+Utility.replace(stnoStr, ",", "','")+"') \n";			            
			     plat012.execute(insertPlat012_3);	

				
				// STEP6 更新學生的班級代號  ,20200107考試教室不寫入
				REGT007DAO regt007 = new REGT007DAO(dbManager, conn);
				String updateRegt007Sql = 	        
				        " UPDATE REGT007 A SET MASTER_CLASS_CODE='"+netwkClassName+"', ASS_CLASS_CODE='ZZ"+thirdClassCode + fourClassCode +Utility.fillZero(i+"",2)+"' "+
				        " ,TUT_CLASS_CODE = (SELECT CENTER_ABRCODE||TO_CHAR(SUBSTR(A.TUT_CMPS_CODE,1,1))||'"+thirdClassCode + fourClassCode +Utility.fillZero(i+"",2)+"' FROM STUT003 JOIN SYST002 ON STUT003.CENTER_CODE=SYST002.CENTER_CODE WHERE A.STNO=STUT003.STNO) "+
						//" ,EXAM_CLASSM_CODE = (SELECT CENTER_ABRCODE||TO_CHAR(SUBSTR(A.TUT_CMPS_CODE,1,1))||'"+thirdClassCode+Utility.fillZero(i+"",3)+"' FROM STUT003 JOIN SYST002 ON STUT003.CENTER_CODE=SYST002.CENTER_CODE WHERE A.STNO=STUT003.STNO) "+
				        " ,EXAM_CLASSM_CODE = '' "+
				        " ,PLA_UPD_USER_ID = '"+(String)session.getAttribute("USER_ID")+"',PLA_UPD_DATE = '"+Utility.dbStr(DateUtil.getNowDate())+"' ,PLA_UPD_TIME = '"+Utility.dbStr(DateUtil.getNowTimeS())+"',PLA_ROWSTAMP = '"+ Utility.dbStr(DateUtil.getNowTimeMs()) +"' \n"+ 
				        " WHERE "+
				        "		AYEAR='"+AYEAR[0]+"' "+
				        "	AND SMS='"+SMS[0]+"' "+
				        "	AND CRSNO='"+crsno+"' "+
				        "	AND UNQUAL_TAKE_MK='N' "+
				        "	AND UNTAKECRS_MK='N' "+
				        "	AND PAYMENT_STATUS != '1' "+
				        "	AND MASTER_CLASS_CODE='"+netwkClassName+"' "+
				        //"	AND EXISTS (SELECT 1 FROM STUT003 B JOIN SYST002 C ON B.CENTER_CODE=C.CENTER_CODE WHERE A.STNO=B.STNO AND C.CENTER_ABRCODE BETWEEN '"+startCenter+"' AND '"+endCenter+"') ";
				        "AND A.STNO IN ('"+Utility.replace(stnoStr, ",", "','")+"') \n";
				regt007.execute(updateRegt007Sql);
				
				
				if(i==1){
					//
					for(int j=1; j<=classNum; j++){
						plat012 = new PLAT012DAO(dbManager, conn,(String)session.getAttribute("USER_ID"));
						plat012.setAYEAR(AYEAR[0]);
						plat012.setSMS(SMS[0]);
						plat012.setCRSNO(crsno);
						plat012.setCENTER_ABRCODE("0");
						plat012.setCMPS_CODE("Z00");
						
						if("@0@0".equals(netwkClassName)) {
							plat012.setCLASS_CODE("ZZZ0"+Utility.fillZero(j+"",2));
						} else if("@0@1".equals(netwkClassName)) {
							plat012.setCLASS_CODE("ZZZ1"+Utility.fillZero(j+"",2));
						} else if("@0@2".equals(netwkClassName)) {
							plat012.setCLASS_CODE("ZZZ2"+Utility.fillZero(j+"",2));
						}
						
						plat012.setSEGMENT_CODE("1");
						plat012.setSECTION_CODE("1");
						plat012.setSWEEK("1");
						plat012.setCLASS_KIND("2");
						plat012.setCLSSRM_CODE(netwkClassName);
						plat012.setCLS_YN("Y");
						plat012.insert();
					}
				}
				
			}
			
			
				
		}
		rs.close();
		
		dbManager.commit();

		out.println(DataToJson.successJson());
	}
	catch (Exception ex)
	{
		ex.printStackTrace();
		/** Rollback Transaction */
		dbManager.rollback();
		throw ex;
	}
	finally
	{
		dbManager.close();
	}
}

/** 執行網路編班-中心學生數拆班_台北中心 */
public void doDelete_02(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{
    DBManager dbmanager=null;
    DBResult rs = null;
	try
	{
		Connection	conn		=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));

		String netwkClassName = requestMap.get("NETWK_CLASS_NAME").toString().substring(0,4); // 網路班原班代號 ex:@0@0
		
		String thirdClassCode = "Z";
		String fourClassCode = "";
		if("@0@0".equals(netwkClassName)) {
			fourClassCode = "0";
		} else if("@0@1".equals(netwkClassName)) {
			fourClassCode = "1";
		} else if("@0@2".equals(netwkClassName)) {
			fourClassCode = "2";
		}
		
		
        String[]    AYEAR   =   Utility.split(requestMap.get("AYEAR").toString(), ",");
        String[]    SMS     =   Utility.split(requestMap.get("SMS").toString(), ",");
		
		// STEP1. 刪除PLAT012這各科目網路班的資料
		PLAT012DAO	PLAT012	=	new PLAT012DAO(dbManager, conn, requestMap, session);		
		PLAT012.delete( " AYEAR='"+AYEAR[0]+"' AND SMS='"+SMS[0]+"' AND CENTER_ABRCODE='2' AND (SUBSTR(CLASS_CODE,3,2)='"+thirdClassCode+""+fourClassCode +"' OR CLASS_CODE='"+netwkClassName+"') " );
		
		// 原本是一科開一班,現在有可能一開開多班,因此改成用下面的方式
		// STEP2:取得每科要分成幾班,如為0表示不開班
		PLAT033DAO plat033 = new PLAT033DAO(dbManager, conn);
		plat033.setResultColumn("CRSNO, CLASS_NUM");
		plat033.setWhere(
			"	 AYEAR='"+AYEAR[0]+"' "+
			"AND SMS='"+SMS[0]+"' "+
			"AND NETWK_CLASS='"+requestMap.get("NETWK_CLASS")+"' "+
			"AND CLASS_NUM>0 "
		);
		rs = plat033.query();
		
		
		// 一次處理一科
		while(rs.next()){
			String crsno = rs.getString("CRSNO");
			int classNum = rs.getInt("CLASS_NUM");
			
			String sql = 
					"SELECT a.STNO "+ 
					"FROM regt007 a \n"+
					"JOIN stut003 b on a.STNO=b.stno and b.center_code = '02' \n"+
					"JOIN SYST002 C ON B.CENTER_CODE=C.CENTER_CODE \n"+
					"WHERE A.AYEAR='"+AYEAR[0]+"' \n"+ 
					"AND A.SMS='"+SMS[0]+"' \n"+
					"AND A.CRSNO='"+crsno+"' \n"+
					"AND A.MASTER_CLASS_CODE='"+netwkClassName+"' \n"+
					"AND A.TUT_CMPS_CODE IS NOT NULL "+
					"AND A.UNQUAL_TAKE_MK = 'N' "+
					"AND A.UNTAKECRS_MK = 'N' "+
					"AND A.PAYMENT_STATUS != '1' "+
					"ORDER BY B.STNO";
							
			Vector st = new Vector();
			Vector vtSt = UtilityX.getvtData(dbManager, conn, sql);
			int cNum = (vtSt.size() / classNum) + ((vtSt.size() % classNum != 0) ? 1: 0);
			System.out.println(crsno+"X"+vtSt.size() +"X"+ classNum + "X" +cNum);
			StringBuffer d = new StringBuffer();
			for (int i = 1; i <= vtSt.size(); i++){		
				String stno = Utility.nullToSpace(((Hashtable)vtSt.get(i-1)).get("STNO")) ;
				d.append(stno).append(",");
				if(i % cNum == 0 ){
					if(d.length() > 0) {
			            d.delete(d.length()-1, d.length());
			        }
					st.add(d.toString());
					d = new StringBuffer();
				} 
			}	
			
			if(d.length()!=0){
				if(d.length() > 0) {
		            d.delete(d.length()-1, d.length());
		        }
				st.add(d.toString());
			}
			
			for (int i = 1; i <= st.size(); i++){		
				String stnoStr =  Utility.nullToSpace(st.get(i-1));
				//System.out.println(stnoStr);
				// STEP4 輸入新的校本部班級代碼，面授班 
				// 每個中心寫入一筆CLASS_KIND=1(一般面授)--FOR 考試  但仍需新增CLASS_KIND=2(網路)
				PLAT012DAO plat012 = new PLAT012DAO(dbManager, conn);
				String insertPlat012_2 = 
			            "INSERT INTO PLAT012(AYEAR, SMS, CLASS_CODE, CENTER_ABRCODE, CMPS_CODE, SWEEK, CLASS_KIND, CRSNO, SEGMENT_CODE, SECTION_CODE, TCH_IDNO, CLSSRM_CODE, CLS_YN, UPD_USER_ID, UPD_DATE, UPD_TIME, UPD_MK, ROWSTAMP) \n"+
			            "SELECT DISTINCT A.AYEAR ,A.SMS, C.CENTER_ABRCODE||SUBSTR(A.TUT_CMPS_CODE,1,1)||'"+thirdClassCode + fourClassCode +Utility.fillZero(i+"",2)+"' AS CLASS_CODE, C.CENTER_ABRCODE, A.TUT_CMPS_CODE AS CMPS_CODE, \n"+ 
						"    '1' AS SWEEK, '1' AS CLASS_KIND , A.CRSNO, '1' AS SEGMENT_CODE, '1' AS SECTION_CODE, '', '"+netwkClassName+"' AS CLSSRM_CODE, 'Y' AS CLS_YN, \n"+  
						"    '"+(String)session.getAttribute("USER_ID")+"','"+Utility.dbStr(DateUtil.getNowDate())+"' ,'"+Utility.dbStr(DateUtil.getNowTimeS())+"','1','"+ Utility.dbStr(DateUtil.getNowTimeMs()) +"' \n"+  
						"FROM regt007 a \n"+
						"JOIN stut003 b on a.STNO=b.stno and b.center_code = '02' \n"+
						"JOIN SYST002 C ON B.CENTER_CODE=C.CENTER_CODE \n"+
						"WHERE \n"+
						"     A.AYEAR='"+AYEAR[0]+"' \n"+ 
						"AND A.SMS='"+SMS[0]+"' \n"+
						"AND A.CRSNO='"+crsno+"' \n"+
						"AND A.MASTER_CLASS_CODE='"+netwkClassName+"' \n"+
						"AND A.STNO IN ('"+Utility.replace(stnoStr, ",", "','")+"') \n"; 			            
				plat012.execute(insertPlat012_2);
				

				// STEP5  新增CLASS_KIND=2(網路)
				plat012 = new PLAT012DAO(dbManager, conn);
				String insertPlat012_3 = 	        
			            "INSERT INTO PLAT012(AYEAR, SMS, CLASS_CODE, CENTER_ABRCODE, CMPS_CODE, SWEEK, CLASS_KIND, CRSNO, SEGMENT_CODE, SECTION_CODE, TCH_IDNO, CLSSRM_CODE, CLS_YN, UPD_USER_ID, UPD_DATE, UPD_TIME, UPD_MK, ROWSTAMP) "+
			            "SELECT DISTINCT A.AYEAR ,A.SMS, 'ZZ"+thirdClassCode + fourClassCode +Utility.fillZero(i+"",2)+"' AS CLASS_CODE, C.CENTER_ABRCODE, A.TUT_CMPS_CODE AS CMPS_CODE, \n"+ 
						"    '1' AS SWEEK, '2' AS CLASS_KIND , A.CRSNO, '1' AS SEGMENT_CODE, '1' AS SECTION_CODE, '', '"+netwkClassName+"' AS CLSSRM_CODE, 'Y' AS CLS_YN, \n"+  
						"    '"+(String)session.getAttribute("USER_ID")+"','"+Utility.dbStr(DateUtil.getNowDate())+"' ,'"+Utility.dbStr(DateUtil.getNowTimeS())+"','1','"+ Utility.dbStr(DateUtil.getNowTimeMs()) +"' \n"+  
						"FROM regt007 a \n"+
						"JOIN stut003 b on a.STNO=b.stno and b.center_code = '02' \n"+
						"JOIN SYST002 C ON B.CENTER_CODE=C.CENTER_CODE \n"+
						"WHERE \n"+
						"     A.AYEAR='"+AYEAR[0]+"' \n"+ 
						"AND A.SMS='"+SMS[0]+"' \n"+
						"AND A.CRSNO='"+crsno+"' \n"+
						"AND a.MASTER_CLASS_CODE='"+netwkClassName+"' \n"+
						"AND A.STNO IN ('"+Utility.replace(stnoStr, ",", "','")+"') \n";			            
			     plat012.execute(insertPlat012_3);	

				
				// STEP6 更新學生的班級代號  ,20200107考試教室不寫入
				REGT007DAO regt007 = new REGT007DAO(dbManager, conn);
				String updateRegt007Sql = 	        
				        " UPDATE REGT007 A SET MASTER_CLASS_CODE='"+netwkClassName+"', ASS_CLASS_CODE='ZZ"+thirdClassCode + fourClassCode +Utility.fillZero(i+"",2)+"' "+
				        " ,TUT_CLASS_CODE = (SELECT CENTER_ABRCODE||TO_CHAR(SUBSTR(A.TUT_CMPS_CODE,1,1))||'"+thirdClassCode + fourClassCode +Utility.fillZero(i+"",2)+"' FROM STUT003 JOIN SYST002 ON STUT003.CENTER_CODE=SYST002.CENTER_CODE WHERE A.STNO=STUT003.STNO) "+
						//" ,EXAM_CLASSM_CODE = (SELECT CENTER_ABRCODE||TO_CHAR(SUBSTR(A.TUT_CMPS_CODE,1,1))||'"+thirdClassCode+Utility.fillZero(i+"",3)+"' FROM STUT003 JOIN SYST002 ON STUT003.CENTER_CODE=SYST002.CENTER_CODE WHERE A.STNO=STUT003.STNO) "+
				        " ,EXAM_CLASSM_CODE = '' "+
				        " ,PLA_UPD_USER_ID = '"+(String)session.getAttribute("USER_ID")+"',PLA_UPD_DATE = '"+Utility.dbStr(DateUtil.getNowDate())+"' ,PLA_UPD_TIME = '"+Utility.dbStr(DateUtil.getNowTimeS())+"',PLA_ROWSTAMP = '"+ Utility.dbStr(DateUtil.getNowTimeMs()) +"' \n"+ 
				        " WHERE "+
				        "		AYEAR='"+AYEAR[0]+"' "+
				        "	AND SMS='"+SMS[0]+"' "+
				        "	AND CRSNO='"+crsno+"' "+
				        "	AND UNQUAL_TAKE_MK='N' "+
				        "	AND UNTAKECRS_MK='N' "+
				        "	AND PAYMENT_STATUS != '1' "+
				        "	AND MASTER_CLASS_CODE='"+netwkClassName+"' "+
				        //"	AND EXISTS (SELECT 1 FROM STUT003 B JOIN SYST002 C ON B.CENTER_CODE=C.CENTER_CODE WHERE A.STNO=B.STNO AND C.CENTER_ABRCODE BETWEEN '"+startCenter+"' AND '"+endCenter+"') ";
				        "AND A.STNO IN ('"+Utility.replace(stnoStr, ",", "','")+"') \n";
				regt007.execute(updateRegt007Sql);
				
				 /**台北中心不須要再寫校本網路班
				if(i==1){
					//
					for(int j=1; j<=classNum; j++){
						plat012 = new PLAT012DAO(dbManager, conn,(String)session.getAttribute("USER_ID"));
						plat012.setAYEAR(AYEAR[0]);
						plat012.setSMS(SMS[0]);
						plat012.setCRSNO(crsno);
						plat012.setCENTER_ABRCODE("0");
						plat012.setCMPS_CODE("Z00");
						
						if("@0@0".equals(netwkClassName)) {
							plat012.setCLASS_CODE("ZZZ0"+Utility.fillZero(j+"",2));
						} else if("@0@1".equals(netwkClassName)) {
							plat012.setCLASS_CODE("ZZZ1"+Utility.fillZero(j+"",2));
						} else if("@0@2".equals(netwkClassName)) {
							plat012.setCLASS_CODE("ZZZ2"+Utility.fillZero(j+"",2));
						}
						
						plat012.setSEGMENT_CODE("1");
						plat012.setSECTION_CODE("1");
						plat012.setSWEEK("1");
						plat012.setCLASS_KIND("2");
						plat012.setCLSSRM_CODE(netwkClassName);
						plat012.setCLS_YN("Y");
						plat012.insert();
					}
				}
				*/
			}
			
			
				
		}
		rs.close();
		
		dbManager.commit();

		out.println(DataToJson.successJson());
	}
	catch (Exception ex)
	{
		ex.printStackTrace();
		/** Rollback Transaction */
		dbManager.rollback();
		throw ex;
	}
	finally
	{
		dbManager.close();
	}
}


/** 執行網路編班-中心學生數拆班_排除台北中心 */
public void doDelete_other(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{
    DBManager dbmanager=null;
    DBResult rs = null;
	try
	{
		Connection	conn		=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));

		String netwkClassName = requestMap.get("NETWK_CLASS_NAME").toString().substring(0,4); // 網路班原班代號 ex:@0@0
		
		String thirdClassCode = "Z";
		String fourClassCode = "";
		if("@0@0".equals(netwkClassName)) {
			fourClassCode = "0";
		} else if("@0@1".equals(netwkClassName)) {
			fourClassCode = "1";
		} else if("@0@2".equals(netwkClassName)) {
			fourClassCode = "2";
		}
		
		
        String[]    AYEAR   =   Utility.split(requestMap.get("AYEAR").toString(), ",");
        String[]    SMS     =   Utility.split(requestMap.get("SMS").toString(), ",");
		
		// STEP1. 刪除PLAT012這各科目網路班的資料
		PLAT012DAO	PLAT012	=	new PLAT012DAO(dbManager, conn, requestMap, session);		
		PLAT012.delete( " AYEAR='"+AYEAR[0]+"' AND SMS='"+SMS[0]+"' AND CENTER_ABRCODE !='2' AND (SUBSTR(CLASS_CODE,3,2)='"+thirdClassCode+""+fourClassCode +"' OR CLASS_CODE='"+netwkClassName+"') " );
		
		// 原本是一科開一班,現在有可能一開開多班,因此改成用下面的方式
		// STEP2:取得每科要分成幾班,如為0表示不開班
		PLAT033DAO plat033 = new PLAT033DAO(dbManager, conn);
		plat033.setResultColumn("CRSNO, CLASS_NUM");
		plat033.setWhere(
			"	 AYEAR='"+AYEAR[0]+"' "+
			"AND SMS='"+SMS[0]+"' "+
			"AND NETWK_CLASS='"+requestMap.get("NETWK_CLASS")+"' "+
			"AND CLASS_NUM>0 "
		);
		rs = plat033.query();
		
		
		// 一次處理一科
		while(rs.next()){
			String crsno = rs.getString("CRSNO");
			int classNum = rs.getInt("CLASS_NUM");
			
			String sql = 
					"SELECT a.STNO "+ 
					"FROM regt007 a \n"+
					"JOIN stut003 b on a.STNO=b.stno and b.center_code != '02' \n"+
					"JOIN SYST002 C ON B.CENTER_CODE=C.CENTER_CODE \n"+
					"WHERE A.AYEAR='"+AYEAR[0]+"' \n"+ 
					"AND A.SMS='"+SMS[0]+"' \n"+
					"AND A.CRSNO='"+crsno+"' \n"+
					"AND A.MASTER_CLASS_CODE='"+netwkClassName+"' \n"+
					"AND A.TUT_CMPS_CODE IS NOT NULL "+
					"AND A.UNQUAL_TAKE_MK = 'N' "+
					"AND A.UNTAKECRS_MK = 'N' "+
					"AND A.PAYMENT_STATUS != '1' "+
					"ORDER BY B.CENTER_CODE";
							
			Vector st = new Vector();
			Vector vtSt = UtilityX.getvtData(dbManager, conn, sql);
			int cNum = (vtSt.size() / classNum) + ((vtSt.size() % classNum != 0) ? 1: 0);
			System.out.println(crsno+"X"+vtSt.size() +"X"+ classNum + "X" +cNum);
			StringBuffer d = new StringBuffer();
			for (int i = 1; i <= vtSt.size(); i++){		
				String stno = Utility.nullToSpace(((Hashtable)vtSt.get(i-1)).get("STNO")) ;
				d.append(stno).append(",");
				if(i % cNum == 0 ){
					if(d.length() > 0) {
			            d.delete(d.length()-1, d.length());
			        }
					st.add(d.toString());
					d = new StringBuffer();
				} 
			}	
			
			if(d.length()!=0){
				if(d.length() > 0) {
		            d.delete(d.length()-1, d.length());
		        }
				st.add(d.toString());
			}
			
			for (int i = 1; i <= st.size(); i++){		
				String stnoStr =  Utility.nullToSpace(st.get(i-1));
				//System.out.println(stnoStr);
				// STEP4 輸入新的校本部班級代碼，面授班 
				// 每個中心寫入一筆CLASS_KIND=1(一般面授)--FOR 考試  但仍需新增CLASS_KIND=2(網路)
				PLAT012DAO plat012 = new PLAT012DAO(dbManager, conn);
				String insertPlat012_2 = 
			            "INSERT INTO PLAT012(AYEAR, SMS, CLASS_CODE, CENTER_ABRCODE, CMPS_CODE, SWEEK, CLASS_KIND, CRSNO, SEGMENT_CODE, SECTION_CODE, TCH_IDNO, CLSSRM_CODE, CLS_YN, UPD_USER_ID, UPD_DATE, UPD_TIME, UPD_MK, ROWSTAMP) \n"+
			            "SELECT DISTINCT A.AYEAR ,A.SMS, C.CENTER_ABRCODE||SUBSTR(A.TUT_CMPS_CODE,1,1)||'"+thirdClassCode + fourClassCode +Utility.fillZero(i+"",2)+"' AS CLASS_CODE, C.CENTER_ABRCODE, A.TUT_CMPS_CODE AS CMPS_CODE, \n"+ 
						"    '1' AS SWEEK, '1' AS CLASS_KIND , A.CRSNO, '1' AS SEGMENT_CODE, '1' AS SECTION_CODE, '', '"+netwkClassName+"' AS CLSSRM_CODE, 'Y' AS CLS_YN, \n"+  
						"    '"+(String)session.getAttribute("USER_ID")+"','"+Utility.dbStr(DateUtil.getNowDate())+"' ,'"+Utility.dbStr(DateUtil.getNowTimeS())+"','1','"+ Utility.dbStr(DateUtil.getNowTimeMs()) +"' \n"+  
						"FROM regt007 a \n"+
						"JOIN stut003 b on a.STNO=b.stno and b.center_code != '02' \n"+
						"JOIN SYST002 C ON B.CENTER_CODE=C.CENTER_CODE \n"+
						"WHERE \n"+
						"     A.AYEAR='"+AYEAR[0]+"' \n"+ 
						"AND A.SMS='"+SMS[0]+"' \n"+
						"AND A.CRSNO='"+crsno+"' \n"+
						"AND A.MASTER_CLASS_CODE='"+netwkClassName+"' \n"+
						"AND A.STNO IN ('"+Utility.replace(stnoStr, ",", "','")+"') \n"; 			            
				plat012.execute(insertPlat012_2);
				

				// STEP5  新增CLASS_KIND=2(網路)
				plat012 = new PLAT012DAO(dbManager, conn);
				String insertPlat012_3 = 	        
			            "INSERT INTO PLAT012(AYEAR, SMS, CLASS_CODE, CENTER_ABRCODE, CMPS_CODE, SWEEK, CLASS_KIND, CRSNO, SEGMENT_CODE, SECTION_CODE, TCH_IDNO, CLSSRM_CODE, CLS_YN, UPD_USER_ID, UPD_DATE, UPD_TIME, UPD_MK, ROWSTAMP) "+
			            "SELECT DISTINCT A.AYEAR ,A.SMS, 'ZZ"+thirdClassCode + fourClassCode +Utility.fillZero(i+"",2)+"' AS CLASS_CODE, C.CENTER_ABRCODE, A.TUT_CMPS_CODE AS CMPS_CODE, \n"+ 
						"    '1' AS SWEEK, '2' AS CLASS_KIND , A.CRSNO, '1' AS SEGMENT_CODE, '1' AS SECTION_CODE, '', '"+netwkClassName+"' AS CLSSRM_CODE, 'Y' AS CLS_YN, \n"+  
						"    '"+(String)session.getAttribute("USER_ID")+"','"+Utility.dbStr(DateUtil.getNowDate())+"' ,'"+Utility.dbStr(DateUtil.getNowTimeS())+"','1','"+ Utility.dbStr(DateUtil.getNowTimeMs()) +"' \n"+  
						"FROM regt007 a \n"+
						"JOIN stut003 b on a.STNO=b.stno and b.center_code != '02' \n"+
						"JOIN SYST002 C ON B.CENTER_CODE=C.CENTER_CODE \n"+
						"WHERE \n"+
						"     A.AYEAR='"+AYEAR[0]+"' \n"+ 
						"AND A.SMS='"+SMS[0]+"' \n"+
						"AND A.CRSNO='"+crsno+"' \n"+
						"AND a.MASTER_CLASS_CODE='"+netwkClassName+"' \n"+
						"AND A.STNO IN ('"+Utility.replace(stnoStr, ",", "','")+"') \n";			            
			     plat012.execute(insertPlat012_3);	

				
				// STEP6 更新學生的班級代號  ,20200107考試教室不寫入
				REGT007DAO regt007 = new REGT007DAO(dbManager, conn);
				String updateRegt007Sql = 	        
				        " UPDATE REGT007 A SET MASTER_CLASS_CODE='"+netwkClassName+"', ASS_CLASS_CODE='ZZ"+thirdClassCode + fourClassCode +Utility.fillZero(i+"",2)+"' "+
				        " ,TUT_CLASS_CODE = (SELECT CENTER_ABRCODE||TO_CHAR(SUBSTR(A.TUT_CMPS_CODE,1,1))||'"+thirdClassCode + fourClassCode +Utility.fillZero(i+"",2)+"' FROM STUT003 JOIN SYST002 ON STUT003.CENTER_CODE=SYST002.CENTER_CODE WHERE A.STNO=STUT003.STNO) "+
						//" ,EXAM_CLASSM_CODE = (SELECT CENTER_ABRCODE||TO_CHAR(SUBSTR(A.TUT_CMPS_CODE,1,1))||'"+thirdClassCode+Utility.fillZero(i+"",3)+"' FROM STUT003 JOIN SYST002 ON STUT003.CENTER_CODE=SYST002.CENTER_CODE WHERE A.STNO=STUT003.STNO) "+
				        " ,EXAM_CLASSM_CODE = '' "+
				        " ,PLA_UPD_USER_ID = '"+(String)session.getAttribute("USER_ID")+"',PLA_UPD_DATE = '"+Utility.dbStr(DateUtil.getNowDate())+"' ,PLA_UPD_TIME = '"+Utility.dbStr(DateUtil.getNowTimeS())+"',PLA_ROWSTAMP = '"+ Utility.dbStr(DateUtil.getNowTimeMs()) +"' \n"+ 
				        " WHERE "+
				        "		AYEAR='"+AYEAR[0]+"' "+
				        "	AND SMS='"+SMS[0]+"' "+
				        "	AND CRSNO='"+crsno+"' "+
				        "	AND UNQUAL_TAKE_MK='N' "+
				        "	AND UNTAKECRS_MK='N' "+
				        "	AND PAYMENT_STATUS != '1' "+
				        "	AND MASTER_CLASS_CODE='"+netwkClassName+"' "+
				        //"	AND EXISTS (SELECT 1 FROM STUT003 B JOIN SYST002 C ON B.CENTER_CODE=C.CENTER_CODE WHERE A.STNO=B.STNO AND C.CENTER_ABRCODE BETWEEN '"+startCenter+"' AND '"+endCenter+"') ";
				        "AND A.STNO IN ('"+Utility.replace(stnoStr, ",", "','")+"') \n";
				regt007.execute(updateRegt007Sql);
				
				
				if(i==1){
					//
					for(int j=1; j<=classNum; j++){
						plat012 = new PLAT012DAO(dbManager, conn,(String)session.getAttribute("USER_ID"));
						plat012.setAYEAR(AYEAR[0]);
						plat012.setSMS(SMS[0]);
						plat012.setCRSNO(crsno);
						plat012.setCENTER_ABRCODE("0");
						plat012.setCMPS_CODE("Z00");
						
						if("@0@0".equals(netwkClassName)) {
							plat012.setCLASS_CODE("ZZZ0"+Utility.fillZero(j+"",2));
						} else if("@0@1".equals(netwkClassName)) {
							plat012.setCLASS_CODE("ZZZ1"+Utility.fillZero(j+"",2));
						} else if("@0@2".equals(netwkClassName)) {
							plat012.setCLASS_CODE("ZZZ2"+Utility.fillZero(j+"",2));
						}
						
						plat012.setSEGMENT_CODE("1");
						plat012.setSECTION_CODE("1");
						plat012.setSWEEK("1");
						plat012.setCLASS_KIND("2");
						plat012.setCLSSRM_CODE(netwkClassName);
						plat012.setCLS_YN("Y");
						plat012.insert();
					}
				}
				
			}
				
		}
		rs.close();
		
		dbManager.commit();

		out.println(DataToJson.successJson());
	}
	catch (Exception ex)
	{
		ex.printStackTrace();
		/** Rollback Transaction */
		dbManager.rollback();
		throw ex;
	}
	finally
	{
		dbManager.close();
	}
}

/** 執行網路編班-以中心進行拆班 */
public void doDelete1(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{
    DBManager dbmanager=null;
    DBResult rs = null;
	try
	{
		Connection	conn		=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));

		String netwkClassName = requestMap.get("NETWK_CLASS_NAME").toString().substring(0,4); // 網路班原班代號 ex:@0@0
		// 規則原因,請見PLAT002GATEWAY.getNetwkClassHt說明
		//String thirdClassCode = ((char)(90-Integer.parseInt(requestMap.get("NETWK_CLASS").toString())+1))+""; // 課程代碼第三碼 ex:Z X Y .. 
		//20200528 第三碼目前全部都改為X 用第四碼0 1 2 做判斷
		String thirdClassCode = "Z";
		String fourClassCode = "";
		if("@0@0".equals(netwkClassName)) {
			fourClassCode = "0";
		} else if("@0@1".equals(netwkClassName)) {
			fourClassCode = "1";
		} else if("@0@2".equals(netwkClassName)) {
			fourClassCode = "2";
		}
		
		
        String[]    AYEAR   =   Utility.split(requestMap.get("AYEAR").toString(), ",");
        String[]    SMS     =   Utility.split(requestMap.get("SMS").toString(), ",");

		/*
		// STEP2 刪除預定編為網路班之科目，但沒編上的學生名單		
		PLAT015DAO plat015 = new PLAT015DAO(dbManager, conn);	
		String deletePlat015 = 
			" DELETE PLAT015  "+
			" WHERE AYEAR||SMS||CENTER_ABRCODE||CMPS_CODE||CRSNO IN " +
			"	(SELECT AYEAR||SMS||CENTER_ABRCODE||CMPS_CODE||CRSNO " +
			"	 FROM PLAT009 " +
			"	 WHERE AYEAR='"+AYEAR[0]+"' AND SMS='"+SMS[0]+"' AND CLASS_KIND IN ('2')) ";
		plat015.execute(deletePlat015);
		*/
		
		
		// STEP1. 刪除PLAT012這各科目網路班的資料
		PLAT012DAO	PLAT012	=	new PLAT012DAO(dbManager, conn, requestMap, session);			
		//PLAT012.delete( " AYEAR='"+AYEAR[0]+"' AND SMS='"+SMS[0]+"' AND (CLASS_CODE LIKE '%Z001' OR CLASS_CODE='@0@0') " );
		// 因原本的網路班是固定@0@0,現有參數檔,且是按參數檔設定一個種類一個種類來編班,因同一科有可能開多班 ,因此班級代碼後面也用%
		PLAT012.delete( " AYEAR='"+AYEAR[0]+"' AND SMS='"+SMS[0]+"' AND (SUBSTR(CLASS_CODE,3,2)='"+thirdClassCode+""+fourClassCode +"' OR CLASS_CODE='"+netwkClassName+"') " );
		
		// 原本是一科開一班,現在有可能一開開多班,因此改成用下面的方式
		// STEP2:取得每科要分成幾班,如為0表示不開班
		PLAT033DAO plat033 = new PLAT033DAO(dbManager, conn);
		plat033.setResultColumn("CRSNO, CLASS_NUM");
		plat033.setWhere(
			"	 AYEAR='"+AYEAR[0]+"' "+
			"AND SMS='"+SMS[0]+"' "+
			"AND NETWK_CLASS='"+requestMap.get("NETWK_CLASS")+"' "+
			"AND CLASS_NUM>0 "
		);
		rs = plat033.query();
		
		// 一次處理一科
		while(rs.next()){
			String crsno = rs.getString("CRSNO");
			int classNum = rs.getInt("CLASS_NUM");
			
			// 如查詢出來的資料無該科資料,則不往下繼續執行
			if(!requestMap.containsKey(crsno+"_STU_NUM"))
				continue;
				
			String[] crsnoStuNum = Utility.split(requestMap.get(crsno+"_STU_NUM").toString(),"_");// 取得該科每個中心的人數

			// 按該科所設定的班級數,設定每一個班級的中心範圍
			Vector allocateClassNum = calClassRanage(classNum, crsnoStuNum);
			
			System.out.println("crsno:"+crsno);
			UtilityX.printList(allocateClassNum, true);
			PLAT012DAO plat012 = new PLAT012DAO(dbManager, conn);
			// 一個迴圈表示一種班
			for(int i=1; i<=allocateClassNum.size(); i++){
				Hashtable classHt = (Hashtable)allocateClassNum.get(i-1);
				String startCenter = classHt.get("START_CENTER_CODE").toString();
				String endCenter = classHt.get("END_CENTER_CODE").toString();
	
				// STEP3 輸入新的校本部班級代碼，網路班
				//Hashtable insertPlat012 = new Hashtable();
				//insertPlat012.put("AYEAR", AYEAR[0]);
				//insertPlat012.put("SMS", SMS[0]);
				//insertPlat012.put("CLASS_CODE", "ZZ"+thirdClassCode+Utility.fillZero(i+"",3));
				//insertPlat012.put("CENTER_ABRCODE", "0");
				//insertPlat012.put("CMPS_CODE", "0");
				//insertPlat012.put("SWEEK", "1");
				//insertPlat012.put("CLASS_KIND", "2");
				//insertPlat012.put("CRSNO", crsno);
				//insertPlat012.put("SEGMENT_CODE", "1");
				//insertPlat012.put("SECTION_CODE", "1");
				//insertPlat012.put("TCH_IDNO", "");
				//insertPlat012.put("CLSSRM_CODE", netwkClassName);
				//insertPlat012.put("CLS_YN", "Y");
				//insertPlat012.put("UPD_MK", "1");
	
				//PLAT012DAO plat012 = new PLAT012DAO(dbManager, conn, insertPlat012, session);
				//plat012.insert();
				

				// STEP4 輸入新的校本部班級代碼，面授班 
				// 每個中心寫入一筆CLASS_KIND=1(一般面授)--FOR 考試  但仍需新增CLASS_KIND=2(網路)
				plat012 = new PLAT012DAO(dbManager, conn);
				String insertPlat012_2 = 
			            "INSERT INTO PLAT012(AYEAR, SMS, CLASS_CODE, CENTER_ABRCODE, CMPS_CODE, SWEEK, CLASS_KIND, CRSNO, SEGMENT_CODE, SECTION_CODE, TCH_IDNO, CLSSRM_CODE, CLS_YN, UPD_USER_ID, UPD_DATE, UPD_TIME, UPD_MK, ROWSTAMP) \n"+
			            "SELECT DISTINCT A.AYEAR ,A.SMS, C.CENTER_ABRCODE||SUBSTR(A.TUT_CMPS_CODE,1,1)||'"+thirdClassCode + fourClassCode +Utility.fillZero(i+"",2)+"' AS CLASS_CODE, C.CENTER_ABRCODE, A.TUT_CMPS_CODE AS CMPS_CODE, \n"+ 
						"    '1' AS SWEEK, '1' AS CLASS_KIND , A.CRSNO, '1' AS SEGMENT_CODE, '1' AS SECTION_CODE, '', '"+netwkClassName+"' AS CLSSRM_CODE, 'Y' AS CLS_YN, \n"+  
						"    '"+(String)session.getAttribute("USER_ID")+"','"+Utility.dbStr(DateUtil.getNowDate())+"' ,'"+Utility.dbStr(DateUtil.getNowTimeS())+"','1','"+ Utility.dbStr(DateUtil.getNowTimeMs()) +"' \n"+  
						"FROM regt007 a \n"+
						"JOIN stut003 b on a.STNO=b.stno \n"+
						"JOIN SYST002 C ON B.CENTER_CODE=C.CENTER_CODE \n"+
						//"JOIN PLAT009 D ON D.AYEAR = A.AYEAR \n"+
                        //"              AND D.SMS = A.SMS \n"+
                        //"              AND D.CRSNO = A.CRSNO \n"+
                        //"              AND D.CENTER_ABRCODE = C.CENTER_ABRCODE \n"+
                        //"              AND D.CMPS_CODE = A.TUT_CMPS_CODE \n"+
                        //"              AND D.CLASS_KIND = '2' \n"+
						"WHERE \n"+
						"     A.AYEAR='"+AYEAR[0]+"' \n"+ 
						"AND A.SMS='"+SMS[0]+"' \n"+
						"AND A.CRSNO='"+crsno+"' \n"+
						"AND A.MASTER_CLASS_CODE='"+netwkClassName+"' \n"+
						"AND C.CENTER_ABRCODE BETWEEN '"+startCenter+"' AND '"+endCenter+"' \n"; 			            
				plat012.execute(insertPlat012_2);
				

				// STEP5  新增CLASS_KIND=2(網路)
				plat012 = new PLAT012DAO(dbManager, conn);
				String insertPlat012_3 = 	        
			            "INSERT INTO PLAT012(AYEAR, SMS, CLASS_CODE, CENTER_ABRCODE, CMPS_CODE, SWEEK, CLASS_KIND, CRSNO, SEGMENT_CODE, SECTION_CODE, TCH_IDNO, CLSSRM_CODE, CLS_YN, UPD_USER_ID, UPD_DATE, UPD_TIME, UPD_MK, ROWSTAMP) "+
			            "SELECT DISTINCT A.AYEAR ,A.SMS, 'ZZ"+thirdClassCode + fourClassCode +Utility.fillZero(i+"",2)+"' AS CLASS_CODE, C.CENTER_ABRCODE, A.TUT_CMPS_CODE AS CMPS_CODE, \n"+ 
						"    '1' AS SWEEK, '2' AS CLASS_KIND , A.CRSNO, '1' AS SEGMENT_CODE, '1' AS SECTION_CODE, '', '"+netwkClassName+"' AS CLSSRM_CODE, 'Y' AS CLS_YN, \n"+  
						"    '"+(String)session.getAttribute("USER_ID")+"','"+Utility.dbStr(DateUtil.getNowDate())+"' ,'"+Utility.dbStr(DateUtil.getNowTimeS())+"','1','"+ Utility.dbStr(DateUtil.getNowTimeMs()) +"' \n"+  
						"FROM regt007 a \n"+
						"JOIN stut003 b on a.STNO=b.stno \n"+
						"JOIN SYST002 C ON B.CENTER_CODE=C.CENTER_CODE \n"+
						//"JOIN PLAT009 D ON D.AYEAR = A.AYEAR \n"+
                        //"              AND D.SMS = A.SMS \n"+
                        //"              AND D.CRSNO = A.CRSNO \n"+
                        //"              AND D.CENTER_ABRCODE = C.CENTER_ABRCODE \n"+
                        //"              AND D.CMPS_CODE = A.TUT_CMPS_CODE \n"+
                        //"              AND D.CLASS_KIND = '2' \n"+
						"WHERE \n"+
						"     A.AYEAR='"+AYEAR[0]+"' \n"+ 
						"AND A.SMS='"+SMS[0]+"' \n"+
						"AND A.CRSNO='"+crsno+"' \n"+
						"AND a.MASTER_CLASS_CODE='"+netwkClassName+"' \n"+
						"AND C.CENTER_ABRCODE BETWEEN '"+startCenter+"' AND '"+endCenter+"' \n";			            
			     plat012.execute(insertPlat012_3);	

				
				// STEP6 更新學生的班級代號  ,20200107考試教室不寫入
				REGT007DAO regt007 = new REGT007DAO(dbManager, conn);
				String updateRegt007Sql = 	        
				        " UPDATE REGT007 A SET MASTER_CLASS_CODE='"+netwkClassName+"', ASS_CLASS_CODE='ZZ"+thirdClassCode + fourClassCode +Utility.fillZero(i+"",2)+"' "+
				        " ,TUT_CLASS_CODE = (SELECT CENTER_ABRCODE||TO_CHAR(SUBSTR(A.TUT_CMPS_CODE,1,1))||'"+thirdClassCode + fourClassCode +Utility.fillZero(i+"",2)+"' FROM STUT003 JOIN SYST002 ON STUT003.CENTER_CODE=SYST002.CENTER_CODE WHERE A.STNO=STUT003.STNO) "+
						//" ,EXAM_CLASSM_CODE = (SELECT CENTER_ABRCODE||TO_CHAR(SUBSTR(A.TUT_CMPS_CODE,1,1))||'"+thirdClassCode+Utility.fillZero(i+"",3)+"' FROM STUT003 JOIN SYST002 ON STUT003.CENTER_CODE=SYST002.CENTER_CODE WHERE A.STNO=STUT003.STNO) "+
				        " ,EXAM_CLASSM_CODE = '' "+
				        " ,PLA_UPD_USER_ID = '"+(String)session.getAttribute("USER_ID")+"',PLA_UPD_DATE = '"+Utility.dbStr(DateUtil.getNowDate())+"' ,PLA_UPD_TIME = '"+Utility.dbStr(DateUtil.getNowTimeS())+"',PLA_ROWSTAMP = '"+ Utility.dbStr(DateUtil.getNowTimeMs()) +"' \n"+ 
				        " WHERE "+
				        "		AYEAR='"+AYEAR[0]+"' "+
				        "	AND SMS='"+SMS[0]+"' "+
				        "	AND CRSNO='"+crsno+"' "+
				        "	AND UNQUAL_TAKE_MK='N' "+
				        "	AND UNTAKECRS_MK='N' "+
				        "	AND PAYMENT_STATUS>'1' "+
				        "	AND MASTER_CLASS_CODE='"+netwkClassName+"' "+
				        "	AND EXISTS (SELECT 1 FROM STUT003 B JOIN SYST002 C ON B.CENTER_CODE=C.CENTER_CODE WHERE A.STNO=B.STNO AND C.CENTER_ABRCODE BETWEEN '"+startCenter+"' AND '"+endCenter+"') ";				        	
				regt007.execute(updateRegt007Sql);
			}
			
			//
			for(int i=1; i<=classNum; i++){
				plat012 = new PLAT012DAO(dbManager, conn,(String)session.getAttribute("USER_ID"));
				plat012.setAYEAR(AYEAR[0]);
				plat012.setSMS(SMS[0]);
				plat012.setCRSNO(crsno);
				plat012.setCENTER_ABRCODE("0");
				plat012.setCMPS_CODE("Z00");
				
				if("@0@0".equals(netwkClassName)) {
					plat012.setCLASS_CODE("ZZZ0"+Utility.fillZero(i+"",2));
				} else if("@0@1".equals(netwkClassName)) {
					plat012.setCLASS_CODE("ZZZ1"+Utility.fillZero(i+"",2));
				} else if("@0@2".equals(netwkClassName)) {
					plat012.setCLASS_CODE("ZZZ2"+Utility.fillZero(i+"",2));
				}
				
				plat012.setSEGMENT_CODE("1");
				plat012.setSECTION_CODE("1");
				plat012.setSWEEK("1");
				plat012.setCLASS_KIND("2");
				plat012.setCLSSRM_CODE(netwkClassName);
				plat012.setCLS_YN("Y");
				plat012.insert();
			}
				
		}
		rs.close();
		

		/** STEP7 網路班沒編成的科目，將這些學生丟到無解名單*/
		/*
 		System.out.println("STEP7 網路班沒編成的科目，將這些學生丟到無解名單 ");		
        if(sql.length() > 0)
            sql.delete(0, sql.length());
        sql.append(
            " INSERT INTO PLAT015(AYEAR, SMS, CENTER_ABRCODE, CMPS_CODE, STNO, CRSNO, CAUSE, RE_SEGMENT, UPD_USER_ID, UPD_DATE, UPD_TIME, UPD_MK,ROWSTAMP) "+
            " SELECT A.AYEAR,A.SMS,D.CENTER_ABRCODE,A.TUT_CMPS_CODE,A.STNO,A.CRSNO,'','','"+(String)session.getAttribute("USER_ID")+"','"+Utility.dbStr(DateUtil.getNowDate())+"' ,'"+Utility.dbStr(DateUtil.getNowTimeS())+"','1','"+ Utility.dbStr(DateUtil.getNowTimeMs()) +"'"+
            " FROM REGT007 A "+
            " JOIN STUT003 C ON A.STNO=C.STNO "+
            " JOIN SYST002 D ON D.CENTER_CODE=C.CENTER_CODE "+
            " JOIN PLAT009 E ON A.AYEAR=E.AYEAR AND A.SMS=E.SMS AND D.CENTER_ABRCODE=E.CENTER_ABRCODE AND A.TUT_CMPS_CODE=E.CMPS_CODE AND A.CRSNO=E.CRSNO AND CLASS_KIND='2' "+
            " WHERE A.AYEAR='"+AYEAR[0]+"' AND A.SMS='"+SMS[0]+"' AND A.UNQUAL_TAKE_MK='N' AND A.UNTAKECRS_MK='N' AND A.PAYMENT_STATUS='2' "
        );
		rs.execute(sql.toString());
		*/
		
		dbManager.commit();

		out.println(DataToJson.successJson());
	}
	catch (Exception ex)
	{
		ex.printStackTrace();
		/** Rollback Transaction */
		dbManager.rollback();
		throw ex;
	}
	finally
	{
		dbManager.close();
	}
}

private Vector calClassRanage(int classNum, String[] crsnoStuNum){
	Vector result = new Vector();
	
	String[] centerAbrcode = {"0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"};
	
	int crsnoTotalStuNum = Integer.parseInt(crsnoStuNum[crsnoStuNum.length-1]);// 先取出該科的總人數,最後一個陣列就是該科總人數
	int averageStu = crsnoTotalStuNum/classNum; // 平均每班總人數
	
	// 開始計算哪些中心要歸在同一班
	int classStuNum = 0; // 班級人數
	String startCenterCode = "0"; // 該班級的起中心
	String endCenterCode = ""; // 該班級的迄中心	
	for(int i=0; i<crsnoStuNum.length-1; i++){
		int crsnoCenterNum =  Integer.parseInt(crsnoStuNum[i]); // 該科某個中心的人數
		int nextCrsnoCenterNum = i==crsnoStuNum.length-2?0:Integer.parseInt(crsnoStuNum[i+1]); // 該科下一個中心的人數
		
		classStuNum+=crsnoCenterNum;
		
		// 判斷累計目前這個中心後和再加上下一個中心的人數後的人數哪一個比較接近平均每班總人數
		// 表示累計至下個中心的人數後超過平均班級人數時,則判斷累計目前這個中心後的人數後最接近平均每班總人數
		if((classStuNum+nextCrsnoCenterNum>=averageStu&&Math.abs(classStuNum-averageStu)<=Math.abs(classStuNum+nextCrsnoCenterNum-averageStu))||i==crsnoStuNum.length-2){
			endCenterCode = i+"";
			
			Hashtable content = new Hashtable();
			content.put("START_CENTER_CODE", centerAbrcode[Integer.parseInt(startCenterCode)]);
			content.put("END_CENTER_CODE", result.size()==classNum-1?centerAbrcode[Integer.parseInt((crsnoStuNum.length-2)+"")]:centerAbrcode[Integer.parseInt(endCenterCode)]);
			content.put("STU_NUM", classStuNum+""); // 該班人數
			content.put("AVERAGE_STU_NUM", averageStu+""); // 平均每班人數
			content.put("CLASS_NUM", classNum+""); // 開班數
			result.add(content);
			
			// 因上面的分配方式,會導致和設定的班數不符,因此如已達開班數,即返回
			if(result.size()==classNum)
				return result;
			
			classStuNum = 0; // 清空放入的班級人數
			startCenterCode = (i+1)+"";
		}
	}
	
	return result;
}

/** 取消編排網路班 */
public void doCancel(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{
    DBManager dbmanager=null;
	try
	{
		Connection	conn		=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));

		String netwkClassName = requestMap.get("NETWK_CLASS_NAME").toString().substring(0,4); // 網路班原班代號

		// 規則原因,請見PLAT002GATEWAY.getNetwkClassHt說明
		//String thirdClassCode = ((char)(90-Integer.parseInt(requestMap.get("NETWK_CLASS").toString())+1))+"";
		//20200528 第三碼目前全部都改為X 用第四碼0 1 2 做判斷
		String thirdClassCode = "Z";
		
        String[]    AYEAR   =   Utility.split(requestMap.get("AYEAR").toString(), ",");
        String[]    SMS     =   Utility.split(requestMap.get("SMS").toString(), ",");

		// STEP1 刪除PLAT012這各科目網路班的資料,連同網路班編班產生的CLASS_KIND=1的班級一起刪除
		PLAT012DAO	PLAT012	=	new PLAT012DAO(dbManager, conn, requestMap, session);
		PLAT012.delete( " AYEAR='"+AYEAR[0]+"' AND SMS='"+SMS[0]+"' AND (SUBSTR(CLASS_CODE,3,1)='"+thirdClassCode+"' OR CLASS_CODE='"+netwkClassName+"') " );

		// STEP2 更新學生的班級代號
		REGT007DAO regt007 = new REGT007DAO(dbManager, conn, session.getAttribute("USER_ID").toString());
		regt007.setTUT_CLASS_CODE(netwkClassName);
		regt007.setASS_CLASS_CODE(netwkClassName);
		regt007.setEXAM_CLASSM_CODE(netwkClassName);
		regt007.update(
			"	 AYEAR='"+AYEAR[0]+"' "+
			"AND SMS='"+SMS[0]+"' "+
			"AND UNQUAL_TAKE_MK='N' "+
			"AND UNTAKECRS_MK='N' "+
			"AND PAYMENT_STATUS>'1' "+
			"AND MASTER_CLASS_CODE='"+netwkClassName+"' "
		);
		
		dbManager.commit();
		
		out.println(DataToJson.successJson());
	}
	catch (Exception ex)
	{
		/** Rollback Transaction */
		dbManager.rollback();
		throw ex;
	}
	finally
	{
		dbManager.close();
	}
}

/** 控制按鈕 */
public void controlerBtn(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{
    DBResult rs = null;
	try
	{
		Connection	conn		=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));
		
		// 規則原因,請見PLAT002GATEWAY.getNetwkClassHt說明
		//String thirdClassCode = ((char)(90-Integer.parseInt(requestMap.get("NETWK_CLASS").toString())+1))+"";
		//20200528 第三碼目前全部都改為X 用第四碼0 1 2 做判斷
		String thirdClassCode = "Z";
		
		// 檢查網路班是否已開設
		PLAT012DAO plat012 = new PLAT012DAO(dbManager, conn);
		plat012.setResultColumn("COUNT(1) AS TOTAL_COUNT");
		plat012.setWhere(
			"	 AYEAR='"+requestMap.get("AYEAR")+"' "+
			"AND SMS='"+requestMap.get("SMS")+"' "+
			"AND substr(class_code,3,1)='"+thirdClassCode+"' "+
			"AND CLASS_KIND='2'"
		);		
		rs = plat012.query();
		
		String plat012Count = "0";
		if(rs.next())
			plat012Count = rs.getString("TOTAL_COUNT");
		rs.close();
		
		// 檢查網路科目班數的參數設定是否已設定
		PLAT033DAO plat033 = new PLAT033DAO(dbManager, conn);
		plat033.setResultColumn("1");
		plat033.setWhere("AYEAR='"+requestMap.get("AYEAR")+"' AND SMS='"+requestMap.get("SMS")+"' ");
		rs = plat033.query();
		
		String plat033Count = "0";
		if(rs.next())
			plat033Count = "1";
		rs.close();
		
		Hashtable result = new Hashtable();
		result.put("PLAT012_COUNT", plat012Count);
		result.put("PLAT033_COUNT", plat033Count);
		
		out.println(DataToJson.htToJson(result));
	}
	catch (Exception ex)
	{
		/** Rollback Transaction */
		dbManager.rollback();
		throw ex;
	}
	finally
	{
		dbManager.close();
	}
}

/** 取得教室可用位子數 */
public void doClear(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{
Connection	conn=null;
	try
	{
        MyLogger mylogger = new MyLogger("PLA015M");
        conn	=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));
        DBAccess rs1 = new DBAccess(conn,mylogger);
        String sql =" UPDATE PLAT017 SET CLS_NUM='0' WHERE 0=0 "+
                    " AND AYEAR='"+requestMap.get("AYEAR").toString() + "' "+
                    " AND SMS='"+requestMap.get("SMS").toString() + "' "+
                    " AND CENTER_ABRCODE='"+requestMap.get("CENTER_ABRCODE").toString() + "' ";
        if(!Utility.checkNull(requestMap.get("CMPS_CODE"), "").equals(""))
            sql +=  " AND CMPS_CODE='"+requestMap.get("CMPS_CODE").toString() + "' ";
        if(!Utility.checkNull(requestMap.get("SEGMENT_CODE"), "").equals(""))
            sql +=  " AND SEGMENT_CODE='"+requestMap.get("SEGMENT_CODE").toString() + "' ";

        rs1.execute(sql.toString());

		/** Commit Transaction */
		dbManager.commit();

		out.println(DataToJson.successJson());
	}
	catch (Exception ex)
	{
		/** Rollback Transaction */
		dbManager.rollback();

		throw ex;
	}
	finally
	{
		dbManager.close();
	}
}
/** 處理查詢 Grid 資料 */
public void getCol(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{

    Connection conn=null;
	try
	{
		conn		=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));
		 PLAT005DAO	 plat005		=	new  PLAT005DAO(dbManager, conn);
		 plat005.setResultColumn(" AYEAR, SMS, CENTER_ABRCODE, CMPS_CODE, SEGMENT_CODE,SECTION_CODE,WEEK_CODE,STIME,ETIME");

        /** == 查詢條件 ST == */
        if(!Utility.checkNull(requestMap.get("AYEAR"), "").equals(""))
            plat005.setAYEAR(Utility.dbStr(requestMap.get("AYEAR")));
        if(!Utility.checkNull(requestMap.get("SMS"), "").equals(""))
            plat005.setSMS(Utility.dbStr(requestMap.get("SMS")));
        if(!Utility.checkNull(requestMap.get("CENTER_ABRCODE"), "").equals(""))
            plat005.setCENTER_ABRCODE(Utility.dbStr(requestMap.get("CENTER_ABRCODE")));
        if(!Utility.checkNull(requestMap.get("CMPS_CODE"), "").equals(""))
            plat005.setCMPS_CODE(Utility.dbStr(requestMap.get("CMPS_CODE")));
        if(!Utility.checkNull(requestMap.get("SEGMENT_CODE"), "").equals(""))
            plat005.setSEGMENT_CODE(Utility.dbStr(requestMap.get("SEGMENT_CODE")));
        /** == 查詢條件 ED == */

        DBResult    rs    =    plat005.query();

        PhraseInfo    info    =    new PhraseInfo();
        info.add("WEEK_CODE", "WEEK");

        out.println(DataToJson.rsToJson(plat005.getTotalRowCount(), rs,info));

	}
	catch (Exception ex)
	{
		throw ex;
	}
	finally
	{
		dbManager.close();
	}

}
/** 處理查詢 Grid 資料 */
public void getLABCRSNO(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{

    Connection conn=null;
	try
	{
        Vector result = new Vector();
        conn       =    dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));
        PLAT017GATEWAY  plat017  =    new PLAT017GATEWAY(dbManager,conn);

        result =  plat017.getCout001Cout002ForUse(requestMap);

        out.println(DataToJson.vtToJson(plat017.getTotalRowCount(), result));
	}
	catch (Exception ex)
	{
		throw ex;
	}
	finally
	{
		dbManager.close();
	}
}
/** 取得預排節次教室科目資訊(PLAT017) */
public void setCRSNO(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{

    Connection conn=null;
	try
	{
		conn		=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));
		 PLAT017DAO	 plat017		=	new  PLAT017DAO(dbManager, conn);
		 plat017.setResultColumn(" DISTINCT AYEAR, SMS, CENTER_ABRCODE, CMPS_CODE, SEGMENT_CODE,SECTION_CODE,CRSNO,CLS_NUM ");

        /** == 查詢條件 ST == */
        if(!Utility.checkNull(requestMap.get("AYEAR"), "").equals(""))
            plat017.setAYEAR(Utility.dbStr(requestMap.get("AYEAR")));
        if(!Utility.checkNull(requestMap.get("SMS"), "").equals(""))
            plat017.setSMS(Utility.dbStr(requestMap.get("SMS")));
        if(!Utility.checkNull(requestMap.get("CENTER_ABRCODE"), "").equals(""))
            plat017.setCENTER_ABRCODE(Utility.dbStr(requestMap.get("CENTER_ABRCODE")));
        if(!Utility.checkNull(requestMap.get("CMPS_CODE"), "").equals(""))
            plat017.setCMPS_CODE(Utility.dbStr(requestMap.get("CMPS_CODE")));
        if(!Utility.checkNull(requestMap.get("SEGMENT_CODE"), "").equals(""))
            plat017.setSEGMENT_CODE(Utility.dbStr(requestMap.get("SEGMENT_CODE")));
        /** == 查詢條件 ED == */

        DBResult    rs    =    plat017.query();

        out.println(DataToJson.rsToJson(plat017.getTotalRowCount(), rs));

	}
	catch (Exception ex)
	{
		throw ex;
	}
	finally
	{
		dbManager.close();
	}

}
/** 取得預排節次教室科目資訊(PLAT017) */
public void doBATCH_SAVE(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{
    Connection conn=null;
    DBAccess rs1 = null;
	try
	{
		String	AYEAR		=	requestMap.get("AYEAR").toString();
		String	SMS		=	requestMap.get("SMS").toString();
		String	CENTER_ABRCODE	=	requestMap.get("CENTER_ABRCODE").toString();
		String	CMPS_CODE	=	requestMap.get("CMPS_CODE").toString();
		String	SEGMENT_CODE	=	requestMap.get("SEGMENT_CODE").toString();
		ArrayList	SECTION_CODE	=	new ArrayList();
		ArrayList	CRSNO	=	new ArrayList();
		ArrayList	CLS_NUM	=	new ArrayList();

        //取得前端所有控制項(節次+科目代碼)
		String[]	DDL_ID_POOR		=	Utility.split(requestMap.get("DDL_ID_POOR").toString(), "|");

        int k=0;
		for (int i = 0; i < DDL_ID_POOR.length; i++)
		{
		    //如果沒控制項ID 則CONTINUE
            if(Utility.checkNull(DDL_ID_POOR[i], "").equals("")) continue;

            SECTION_CODE.add(DDL_ID_POOR[i].substring(0,1));
            CRSNO.add(DDL_ID_POOR[i].substring(1));
            if(Utility.checkNull(requestMap.get(DDL_ID_POOR[i].toString()).toString(), "").equals(""))
                CLS_NUM.add("0");
            else
                CLS_NUM.add(requestMap.get(DDL_ID_POOR[i].toString()).toString());
		}

        MyLogger mylogger = new MyLogger("PLA015M");
        conn	=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));
        rs1 = new DBAccess(conn,mylogger);

        String sql="";

        for (int iii = 0; iii < CRSNO.size(); iii++)
		{
               sql="UPDATE PLAT017 SET CLS_NUM= '"+Utility.dbStr(CLS_NUM.get(iii).toString())+"' WHERE 0=0 ";
               sql+=" AND AYEAR='" + AYEAR + "' ";
               sql+=" AND SMS='" + SMS + "' ";
               sql+=" AND CENTER_ABRCODE='" + CENTER_ABRCODE + "' ";
               sql+=" AND CMPS_CODE='" + CMPS_CODE + "' ";
               sql+=" AND SEGMENT_CODE='" + SEGMENT_CODE + "' ";
               sql+=" AND SECTION_CODE='" + Utility.dbStr(SECTION_CODE.get(iii).toString()) + "' ";
               sql+=" AND CRSNO='" + Utility.dbStr(CRSNO.get(iii).toString()) + "' ";
               int updateCount=rs1.execute(sql);
		}
		dbManager.commit();

        out.println(DataToJson.successJson());

	}
	catch (Exception ex)
	{
	    dbManager.rollback();
		throw ex;
	}
	finally
	{
		dbManager.close();
        rs1=null;
	}
}

/** 儲存開班數 */
public void doSvae1(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{
	try
	{
		Connection conn	=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));
	
		int queryCount = Integer.parseInt(requestMap.get("QUERY_COUNT").toString());
		for(int i=1; i<queryCount; i++){
			PLAT033DAO plat033 = new PLAT033DAO(dbManager, conn, session.getAttribute("USER_ID").toString());				
			plat033.setCLASS_NUM(requestMap.get("CLASS_NUM_"+i).toString());
			plat033.update(
				"AYEAR='"+requestMap.get("AYEAR")+"' AND "+
				"SMS='"+requestMap.get("SMS")+"' AND "+
				"CRSNO='"+requestMap.get("CRSNO_"+i)+"' AND "+
				"NETWK_CLASS='"+requestMap.get("NETWK_CLASS")+"' "
			);
		}
		
		dbManager.commit();
		
        out.println(DataToJson.successJson());

	}
	catch (Exception ex)
	{
	    dbManager.rollback();
		throw ex;
	}
	finally
	{
		dbManager.close();
	}
}


//取得 plat031 LOCK_YN
public void getPlat031mLockYn(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception {
    Connection conn = null;
    try {	    
    	
    	String	AYEAR		=	Utility.checkNull(requestMap.get("AYEAR"),"");
		String	SMS		=	Utility.checkNull(requestMap.get("SMS"),"");
    
		conn	=	dbManager.getConnection(AUTCONNECT.mapConnect("NOU", session));
		PLAT028DAO PLAT028 = new PLAT028DAO(dbManager, conn);
		PLAT028.setResultColumn(" NET_LOCK_YN AS LOCK_YN ");
		PLAT028.setWhere(" AYEAR = '"+Utility.dbStr(AYEAR)+"' AND SMS = '"+Utility.dbStr(SMS)+"' ");
		DBResult    rs    =    PLAT028.query();
        out.println(DataToJson.rsToJson(PLAT028.getTotalRowCount(), rs));
        
    } catch (Exception e) {
        throw e;
    } finally {
        if(conn != null) {
            conn.close();
        }
    }
}

/** 處理查詢 Grid 資料 */
public void doQuery2(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{

//     STEP1 取得所有中心
//     STEP2 取得本學預定開設網路班科目清單
//     STEP3 取得各中心過瀘出來打算開網路班的科目人數
//     STEP4 組成要SHOW出的結構

    Connection conn=null;
    StringBuffer sql = new StringBuffer();

	try
	{
        int NUM1=99;
        if(!Utility.nullToSpace(requestMap.get("NUM1")).equals("")) {
           NUM1=Integer.parseInt(requestMap.get("NUM1").toString());
        }
		
        int peopleCount = Integer.parseInt(requestMap.get("peopleCount").toString());
        
        System.out.println("peopleCount = " + peopleCount);
        
		conn	=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", "0"));
        Vector result = new Vector();        //回傳的vt
        Vector vtCENTER_CODE = new Vector();        //X軸 各中心清單
        Vector vtCRSNO = new Vector();        //Y軸 科目清單
        Hashtable rowHtST_NUM = null;               //X與Y 之間的值 (各科目下的各中心無解人次有多少)
        Hashtable rowHtX = null;                    //X TEMP HT
        Hashtable rowHtY = null;                    //Y TEMP HT
        Hashtable resultHT = new Hashtable();                  //組出HTML的 TEMP HT        conn       =    dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));
        System.out.println("====STEP1 取得所有中心，並組第一行的TITLE");
        //STEP1 取得所有中心
        sql.append(" SELECT A.CENTER_ABBRNAME, B.AYEAR,B.SMS,A.CENTER_ABRCODE,A.CENTER_NAME,CASE WHEN SUM(DECODE(NVL(LOCK1,'X'),'X','0','1'))=0 THEN 'N' "+
	   			   " WHEN SUM(DECODE(NVL(LOCK1,'X'),'X','0','1'))>SUM(CASE WHEN B.LOCK1='Y' THEN '1' ELSE '0' END) THEN 'N' "+
	   			   " WHEN SUM(DECODE(NVL(LOCK1,'X'),'X','0','1'))=SUM(CASE WHEN B.LOCK1='Y' THEN '1' ELSE '0' END) THEN 'Y' ELSE 'N' END AS YN  "+
	   			   " FROM SYST002 A  "+
	   			   " LEFT JOIN PLAT002 B ON A.CENTER_ABRCODE=B.CENTER_ABRCODE AND B.CMPS_KIND IN ('1','2') AND B.AYEAR='"+Utility.nullToSpace(requestMap.get("AYEAR"))+"' AND B.SMS='"+Utility.nullToSpace(requestMap.get("SMS"))+"' "+
	   			   " AND B.NETWK_CLASS = '" + Utility.nullToSpace(requestMap.get("NETWK_CLASS")) + "' " +
 				   " GROUP BY A.CENTER_ABBRNAME, B.AYEAR,B.SMS,A.CENTER_ABRCODE,A.CENTER_NAME "+
	   			   "  ORDER BY A.CENTER_ABRCODE ");

        DBResult rs = null;
        rs = dbManager.getSimpleResultSet(conn);
        rs.open();

        System.out.println(sql.toString());
        rs.executeQuery(sql.toString());

        String tmpStr="";
        String YN="Y";
        while (rs.next()) {
            rowHtX = new Hashtable();
            tmpStr+="<TD resize='on' nowrap>"+rs.getString("CENTER_ABBRNAME")+rs.getString("YN")+"</TD>";
            if(rs.getString("YN").equals("N"))YN="N";
            for (int i = 1; i <= rs.getColumnCount(); i++)
            {
                rowHtX.put(rs.getColumnName(i), rs.getString(i));
            }
            vtCENTER_CODE.add(rowHtX);
        }
        YN = "<input type=hidden name='YN' id='YN' value='"+YN+"'>";
        resultHT.put("TD",tmpStr+YN);
        result.add(resultHT);
        rs.close();

        String nexWorkClassName = requestMap.get("NETWK_CLASS_NAME").toString().substring(0,4);
        
        if(sql.length() > 0)sql.delete(0, sql.length());        
        String step2Sql = 
        	"select SUBSTR(d.CRS_NAME,0,"+NUM1+") AS CCRSNO, d.CRS_NAME, A.CRSNO, A.MASTER_CLASS_CODE,  nvl(f.CLASS_NUM,'0') as CLASS_NUM \n"+
			"from regt007 a \n"+
			"join stut003 b on a.STNO=b.STNO \n"+
			"join syst002 c on b.CENTER_CODE=c.CENTER_CODE \n"+
			"join cout002 d on a.crsno=d.crsno \n"+
			"join syst001 e on e.kind='NETWK_CLASS' AND e.CODE_NAME=a.MASTER_CLASS_CODE "+
			"left join plat033 f on a.ayear=f.ayear and a.sms=f.sms and a.crsno=f.crsno and f.netwk_class=e.CODE \n"+
			"where \n"+
			"    a.AYEAR='"+requestMap.get("AYEAR")+"' \n"+
			"and a.sms='"+requestMap.get("SMS")+"' \n"+
			"and a.MASTER_CLASS_CODE='"+ nexWorkClassName +"' \n"+
			"and a.UNQUAL_TAKE_MK='N' \n"+
			"and a.UNTAKECRS_MK='N' \n"+
			"and a.PAYMENT_STATUS>'1' \n"+
		//	"and exists (select 1 from pert004 d where a.ayear=d.ayear and a.SMS=d.SMS and a.CRSNO=d.CRSNO) \n"+
			"group by a.CRSNO, d.crs_name, A.MASTER_CLASS_CODE, f.CLASS_NUM \n"+
			"order by a.crsno";
        
        rs = null;
        rs = dbManager.getSimpleResultSet(conn);
        rs.open();
        rs.executeQuery(step2Sql);
        rowHtST_NUM = new Hashtable();
        while (rs.next()) {
            rowHtY = new Hashtable();
            for (int i = 1; i <= rs.getColumnCount(); i++)
                rowHtY.put(rs.getColumnName(i), rs.getString(i));
            vtCRSNO.add(rowHtY);            
        }
        rs.close();
		
        if(sql.length() > 0)sql.delete(0, sql.length());
        System.out.println("====STEP3 取得各中心過瀘出來打算開網路班的科目人數");
        //STEP3 取得各中心過瀘出來打算開網路班的科目人數
        /*
        String step3Sql = 
        	"SELECT A.CRSNO||A.CENTER_ABRCODE AS G_KEY,A.CENTER_ABRCODE,A.CRSNO,SUM(A.TAKE_NUM) AS ST_NUM \n"+
        	"FROM PLAT009 A \n"+
        	"JOIN PLAT002 B ON A.AYEAR=B.AYEAR AND A.SMS=B.SMS AND A.CENTER_ABRCODE=B.CENTER_ABRCODE AND A.CMPS_CODE=B.CMPS_CODE AND B.NETWK_CLASS='"+requestMap.get("NETWK_CLASS")+"' \n"+
        	"WHERE \n"+
        	"	 A.CLASS_KIND='2' \n"+
        	"AND A.AYEAR='"+requestMap.get("AYEAR")+"' \n"+
        	"AND A.SMS='"+requestMap.get("SMS")+"' \n"+        	
        	"GROUP BY A.CRSNO||A.CENTER_ABRCODE, A.CENTER_ABRCODE, A.CRSNO \n"+
        	"ORDER BY A.CRSNO||A.CENTER_ABRCODE \n";
        */
        
        String step3Sql = 
        	"select a.CRSNO||c.CENTER_ABRCODE as G_KEY, A.CRSNO, A.MASTER_CLASS_CODE,  COUNT(1) AS ST_NUM \n"+
			"from regt007 a \n"+
			"join stut003 b on a.STNO=b.STNO \n"+
			"join syst002 c on b.CENTER_CODE=c.CENTER_CODE \n"+
			"where \n"+
			"    a.AYEAR='"+requestMap.get("AYEAR")+"' \n"+
			"and a.sms='"+requestMap.get("SMS")+"' \n"+
			"and a.MASTER_CLASS_CODE='" + nexWorkClassName + "' \n"+
			"and a.UNQUAL_TAKE_MK='N' \n"+
			"and a.UNTAKECRS_MK='N' \n"+
			"and a.PAYMENT_STATUS>'1' \n"+
		//	"and exists (select 1 from pert004 d where a.ayear=d.ayear and a.SMS=d.SMS and a.CRSNO=d.CRSNO) \n"+
			"group by a.CRSNO, c.CENTER_ABRCODE, A.MASTER_CLASS_CODE  \n"+
			"order by a.crsno";
        	
        rs = null;
        rs = dbManager.getSimpleResultSet(conn);
        rs.open();
        rs.executeQuery(step3Sql);
        rowHtST_NUM = new Hashtable();
        while (rs.next()) {
            rowHtST_NUM.put(rs.getString("G_KEY"), rs.getString("ST_NUM"));         
        }
        rs.close();

        System.out.println("====STEP4 組成要SHOW出的結構");
        //STEP4 組成要SHOW出的結構
        String TD="";
        int num=0;
        for (int ii=0;ii<vtCRSNO.size();ii++)
        {
            resultHT = new Hashtable();
            rowHtY = new Hashtable();
            rowHtY = (Hashtable)vtCRSNO.get(ii);
			String CEN_ARY="";
            TD="";
            num=0;
            String crsnoStuNum = ""; // 為了編排網路班用,因邊排網路班速度太慢,因此每科每個中心的人數資訊在這取得
            for (int iii=0;iii<vtCENTER_CODE.size();iii++)
            {
                rowHtX = new Hashtable();
                rowHtX = (Hashtable)vtCENTER_CODE.get(iii);
                tmpStr=rowHtY.get("CRSNO").toString()+rowHtX.get("CENTER_ABRCODE").toString();
                if(rowHtST_NUM.containsKey(tmpStr)){
                    TD+="<TD align=center>"+rowHtST_NUM.get(tmpStr).toString()+"</TD>";
                    num+= Integer.parseInt(rowHtST_NUM.get(tmpStr).toString());
					if(CEN_ARY.indexOf(rowHtX.get("CENTER_ABRCODE").toString()) == -1)
						CEN_ARY += ";'"+rowHtX.get("CENTER_ABRCODE").toString()+"'";
					
					crsnoStuNum+=(crsnoStuNum.equals("")?"":"_")+Integer.parseInt(rowHtST_NUM.get(tmpStr).toString());
                }else{
                    TD+="<TD align=center>0</TD>";
                    crsnoStuNum+=(crsnoStuNum.equals("")?"":"_")+"0";
                }
            }
            
            // 放入總計人數
            crsnoStuNum+="_"+num;
            
            if(num >= peopleCount) {
            	continue;
            }
            resultHT.put("AYEAR",Utility.nullToSpace(requestMap.get("AYEAR")));
            resultHT.put("SMS",Utility.nullToSpace(requestMap.get("SMS")));
            resultHT.put("CRSNO",rowHtY.get("CRSNO").toString());
            resultHT.put("CCRSNO",rowHtY.get("CCRSNO").toString());
			resultHT.put("CRS_NAME",rowHtY.get("CRS_NAME").toString());
			resultHT.put("MASTER_CLASS_CODE",rowHtY.get("MASTER_CLASS_CODE").toString()); 
            resultHT.put("ST_COUNT",String.valueOf(num));
            resultHT.put("TD",TD);		
            resultHT.put("CRSNO_ALL_STU_NUM",crsnoStuNum); // 為了編排網路班用,因邊排網路班速度太慢,因此每科每個中心的人數資訊在這取得
			if(CEN_ARY.length()>0)
				CEN_ARY = CEN_ARY.substring(1);
			resultHT.put("CEN_ARY",CEN_ARY);
			resultHT.put("CLASS_NUM",rowHtY.get("CLASS_NUM"));
			
            result.add(resultHT);
        }

        out.println(DataToJson.vtToJson(result));

	}
	catch (Exception ex)
	{
		ex.printStackTrace();
		throw ex;
	}
	finally
	{
		dbManager.close();
	}

}

/** 修改存檔 */
public void doChangeClassMode(JspWriter out, DBManager dbManager, Hashtable requestMap, HttpSession session) throws Exception
{
	try
	{
		Connection	conn	=	dbManager.getConnection(AUTCONNECT.mapConnect("PLA", session));

		/** 修改條件 */
		String[]	AYEAR		=	Utility.split(requestMap.get("AYEAR").toString(), ",");
		String[]	SMS		=	Utility.split(requestMap.get("SMS").toString(), ",");
		String[]	CRSNO		=	Utility.split(requestMap.get("CRSNO").toString(), ",");
		
		String nexWorkClassName = requestMap.get("NETWK_CLASS_NAME").toString().substring(0,4);
		
		String condition = "";
		
		condition += "AYEAR = '" + AYEAR[0] + "' AND SMS = '" + SMS[0] + "' ";
		condition += "AND MASTER_CLASS_CODE = '" + nexWorkClassName + "' ";
		condition += "AND CRSNO IN (";
		for(int i = 0; i < CRSNO.length; i++) {
			if(i == 0) {
				condition += "'" + CRSNO[i] + "'";
			} else {
				condition += ", '" + CRSNO[i] + "'";
			}
		}
		
		condition += ") ";

		System.out.println("condition = " + condition);
		
		/** 處理修改動作 */
		Hashtable ht = new Hashtable();
		ht.put("MASTER_CLASS_CODE", "@0@0");
		ht.put("TUT_CLASS_CODE", "@0@0");
		ht.put("ASS_CLASS_CODE", "@0@0");
		ht.put("STU_TEACHING_TYPE", nexWorkClassName);
		
		REGT007DAO REGT007 = new REGT007DAO(dbManager, conn, ht, session);
		int	updateCount	=	REGT007.update(condition);

		/** Commit Transaction */
		dbManager.commit();

		if (updateCount == 0)
			out.println(DataToJson.faileJson("此筆資料已被異動過, <br>請重新查詢修改!!"));
		else
			out.println(DataToJson.successJson());
	}
	catch (Exception ex)
	{
		/** Rollback Transaction */
		dbManager.rollback();

		throw ex;
	}
	finally
	{
		dbManager.close();
	}
}
%>