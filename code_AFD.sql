select  *
into ##raw_afd
from vpb_whr2.dbo.tbl_w4_doc_f1
where amnd_date >= '2023-10-01'
and SIC_CODE = '5542'
and TARGET_CHANNEL in ('OUR VISA CARDS' , 'OUR MASTERCARDS', 'OUR JCB CARDS')
and trans_type = 'Retail'
and TRANS_COUNTRY <> 'Viet Nam'


drop table TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
select *
into TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
from openquery(mis, 'select * from ##raw_afd')

select *
from TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
where id in ('8005026760'
,'8005078840'
,'8026068720'
,'8005003310')


alter table TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
add card_type varchar (25)




update temp.dbo.Quynhntt17_phan_tich_afd_raw_20240430
set card_type = 'debit'
where left(TARGET_NUMBER, 6) in ('520395', '521377','970432','522384','454119', '415815')


	
update temp.dbo.Quynhntt17_phan_tich_afd_raw_20240430
set card_type = 'credit'
where left(TARGET_NUMBER, 6) in ('520399','524394','523975', '518966' --RETAIL CREDIT
												, '559073', '519930' -- sme
												,'356772' --JCB
												, '406453', '454107', '405280', '419834', '478668') -- visa retail


select *
from TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
where trans_date_update is null

alter table TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
add cif varchar(200)

update a
set a.cif = b.contract_cif
from TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430 a, staging.dbo.card_live b
where a.target_id = b.acnt_contract_id



select RECID, SUB_SEGEMENT_UC
INTO #SEG
from staging.dbo.CUSTOMER_ENDMONTH
where REPORT_MONTH = '202403'


alter table TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
add segment varchar(200)

update a
set a.segment = b.SUB_SEGEMENT_UC
from TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430 a, #SEG b
where a.cif = b.RECID


DROP TABLE #RATE
SELECT BUSINESS_DATE
       , CODE
       , RATE
INTO #RATE
FROM STAGING.DBO.FOCURR_SAVE
WHERE BUSINESS_DATE = '2024-04-16'


ALTER TABLE TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
ADD  RATE FLOAT, GTGD_QD FLOAT



update a
set a.RATE = b.RATE
from TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430 a, #RATE b
where a.SETTL_CURR = b.CODE



UPDATE A
SET GTGD_QD = CONVERT(FLOAT, SETTL_AMOUNT)* RATE
FROM TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430 A


alter table TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
add trans_date_update date

update TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
set trans_date_update = convert(date, TRANS_DATE)

alter table TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
add month varchar(6)

update TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
set month = convert(varchar(6), trans_date_update, 112)

select *
from TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430


--Update rule---

delete from TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
where auth_code is null


delete from TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
where  is_authorization = 'auth'
and REQUEST_CATEGORY = 'Reversal'



bỏ đi auth_code là null 
và (is_authorization = 'auth'
and REQUEST_CATEGORY = 'Reversal')

--chỉ lấy USD, JPA
delete from TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
where trans_curr not in ('USD', 'JPY')
----

----

--Từ tháng 10/2023 - 15/04/2024 có 1998 giao dịch AFD ngoài lãnh thổ Việt Nam

--Khách hàng AF chiếm phần lớn 
SELECT segment , count(distinct(cif)) volume
FROM TEMP.dbo.QUYNHNTT17_PHAN_TICH_AFD_FINAL_RAW_20240430
GROUP BY segment
-- Chủ yếu là dòng thẻ credit

-- Và dòng thẻ MC 
SELECT card_type, left(target_number,1), COUNT(distinct(target_id)), count(distinct(cif))
FROM TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
GROUP BY card_type, left(target_number,1)

SELECT card_type, TARGET_CHANNEL, COUNT(distinct(target_id)), count(distinct(cif))
FROM TEMP.dbo.QUYNHNTT17_PHAN_TICH_AFD_FINAL_RAW_20240430
GROUP BY card_type,  TARGET_CHANNEL

SELECT count(distinct(target_id)) volume
FROM TEMP.dbo.QUYNHNTT17_PHAN_TICH_AFD_FINAL_RAW_20240430


SELECT count(distinct(cif)) volume
FROM TEMP.dbo.QUYNHNTT17_PHAN_TICH_AFD_FINAL_RAW_20240430

--- Mỹ là nước có số lượng giao dịch AFD lớn nhất, đi sâu vào hơn đây cũng là nc có invalid amount lớn nhất theo đầu FIN. Tiếp theo là các nc
SELECT TRANS_COUNTRY, COUNT(*) volume
FROM TEMP.dbo.QUYNHNTT17_PHAN_TICH_AFD_FINAL_RAW_20240430
GROUP BY TRANS_COUNTRY
order by volume desc



---Phân biệt theo đầu thẻ debit vs credit  

Số lượng, số tiền giao dịch/ngày/thẻ và chia theo đồng VNĐ và khác. chỉ check đầu fin 


- Với các giao dịch phát sinh giao dịch AFD/ngày : Số lượng, số tiền giao dịch/ngày/thẻ và chia theo đồng VNĐ và khác

--Phân tích 2 trường hợp

SELECT trans_date_update, TARGET_ID, COUNT(*) SLGD, SUM(GTGD_QD) GTGD
into #credit_jpy
FROM TEMP.dbo.QUYNHNTT17_PHAN_TICH_AFD_FINAL_RAW_20240430
where IS_AUTHORIZATION = 'fin'
and trans_curr = 'JPY'
and card_type = 'credit'
GROUP BY trans_date_update, TARGET_ID
ORDER BY trans_date_update DESC

select min(slgd), max(slgd), min(GTGD), max(GTGD) , avg(GTGD)
from #credit_jpy

---95% 1 thẻ có 1 giao dịch trong ngày
--75% 1 thẻ chi tiêu 1,5tr trong ngày


---Số lượng, tỉ lệ giao dịch auth và fin không trùng nhau trên 1 tháng , tập trung ở đồng tiền nào hoặc trans country nào ?

drop table #auth
select *
into #auth
from TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
where is_authorization = 'auth'

drop table #fin
select *
into #fin
from TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
where is_authorization = 'fin'

drop table ##chenh_lech
select a.month, a.trans_date_update, a.auth_code, a.return_code, a.settl_amount, a.settl_curr, a.target_id, a.target_number, a.trans_amount, a.trans_curr, a.trans_date, a.trans_country , a.trans_city,  a.card_type, a.cif, a.segment, a.gtgd_qd, b.gtgd_qd gtgd_qd_fin, b.settl_amount settl_amount_fin , b.settl_curr settl_cur_fin, b.trans_amount trans_amount_fin, b.trans_curr trans_curr_fin, b.trans_date trans_date_fin, b.trans_city trans_city_fin
into ##chenh_lech
from #auth a
left join #fin b on (a.target_id = b.target_id and a.auth_code = b.auth_code and a.trans_city = b.trans_city)


select *
from ##chenh_lech
where auth_code = '252680'

drop table temp.dbo.quynhntt17_qlrrt_chenh_lech_auth_fin_20240430
select *-- count(distinct(auth_code))
into temp.dbo.quynhntt17_qlrrt_chenh_lech_auth_fin_20240430
from ##chenh_lech
where trans_city_fin is not null
and trans_amount <> trans_amount_fin
and trans_curr = trans_curr_fin

select *
from  temp.dbo.quynhntt17_qlrrt_chenh_lech_auth_fin_20240430

----

select month, trans_curr, card_type,  count(*) volume
from temp.dbo.quynhntt17_qlrrt_chenh_lech_auth_fin_20240430
group by month, trans_curr, card_type
order by trans_curr asc, card_type asc,  month asc
906214
906211

select *
from temp.dbo.quynhntt17_qlrrt_chenh_lech_auth_fin_20240430
where 


-------
alter table temp.dbo.quynhntt17_qlrrt_chenh_lech_auth_fin_20240430
add  chenh_lech_so_tien float 


update temp.dbo.quynhntt17_qlrrt_chenh_lech_auth_fin_20240430
set chenh_lech_so_tien = trans_amount_fin - trans_amount



select min(chenh_lech_so_tien), max(chenh_lech_so_tien), avg(chenh_lech_so_tien)
from  temp.dbo.quynhntt17_qlrrt_chenh_lech_auth_fin_20240430
where trans_curr = 'USD'


select min(chenh_lech_so_tien), max(chenh_lech_so_tien), avg(chenh_lech_so_tien)
from  temp.dbo.quynhntt17_qlrrt_chenh_lech_auth_fin_20240430
where trans_curr = 'JPY'

-------------- Giả thiết các trường hợp chặn từ giao dịch thứ 2, thứ 3/ngày thì số lượng khách hàng bị chặn là bao nhiêu/ngày ----.
select *
from  temp.dbo.quynhntt17_qlrrt_chenh_lech_auth_fin_20240430


select *
INTO TEMP.dbo.QUYNHNTT17_PHAN_TICH_AFD_FINAL_RAW_20240430
from TEMP.dbo.Quynhntt17_phan_tich_afd_raw_20240430
where auth_code in (select auth_code from  TEMP.dbo.quynhntt17_qlrrt_chenh_lech_auth_fin_20240430)



drop table #chan
select trans_date_update, cif, count(*) volume
into #chan
from TEMP.dbo.QUYNHNTT17_PHAN_TICH_AFD_FINAL_RAW_20240430
where is_authorization = 'fin'
and card_type = 'debit'
and trans_curr = 'USD'
group by trans_date_update, cif
order by trans_date_update desc



select min(volume), max(volume), avg(volume)
from #chan


drop table #chan_credit
select trans_date_update, cif, count(*) volume
into #chan_credit
from TEMP.dbo.QUYNHNTT17_PHAN_TICH_AFD_FINAL_RAW_20240430
where is_authorization = 'fin'
and card_type = 'credit'
and trans_curr = 'USD'
group by trans_date_update, cif
order by trans_date_update desc

select *--trans_date_update, cif, count(*) volume
from TEMP.dbo.QUYNHNTT17_PHAN_TICH_AFD_FINAL_RAW_20240430
where is_authorization = 'fin'
and card_type = 'credit'
and trans_curr = 'USD'
select min(volume), max(volume), avg(volume)
from #chan_credit

select *
from TEMP.dbo.quynhntt17_qlrrt_chenh_lech_auth_fin_20240430