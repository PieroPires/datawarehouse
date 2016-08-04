--
USE VAGAS_DW


declare @dt datetime
set @dt = GETDATE()
set @dt = '20160704'

select
    WhichWeekOfMonth = datepart(wk, @dt)
                     - datepart(wk,dateadd(m, DATEDIFF(M, 0, @dt), 0)) + 1

-- ALTER TABLE VAGAS_DW.DATAS ADD SEMANA VARCHAR(20)
UPDATE VAGAS_DW.DATAS SET SEMANA = 'SEMANA ' + CONVERT(VARCHAR,datepart(wk, DATAALTKEY)
     - datepart(wk,dateadd(m, DATEDIFF(M, 0, DATAALTKEY), 0)) + 1)
FROM VAGAS_DW.DATAS

-- SELECT * FROM VAGAS_DW.DATAS