/*
  Заполнение таблицы в несколько этапов псевдослучайными данными
*/
WITH Numbers as (
    SELECT
        ROW_NUMBER() OVER(ORDER BY 1) as RowNumber
    FROM generate_series(1,50) i
),
RawData as (
    SELECT
        n.RowNumber as DateIntervalId,
        CASE n.RowNumber
            WHEN 1 THEN NULL
            ELSE random_number_between(1::INT, (n.RowNumber-1)::INT)
        END as ParentId,
        random_timestamp_between('2000-01-01'::TIMESTAMP, '2100-01-01'::TIMESTAMP)::DATE as StartDate
    FROM Numbers n
)

INSERT INTO public.DateInterval (
    DateIntervalId,
    ParentId,
    IsParent,
    StartDate,
    FinishDate
)
SELECT
    rd.DateIntervalId,
    rd.ParentId,
    EXISTS(SELECT 1 FROM RawData rdi WHERE rdi.ParentId = rd.DateIntervalId) as IsParent,
    rd.StartDate,
    CASE 
      -- иногда генерируем КТ
      WHEN random() < 0.3 THEN rd.StartDate
      ELSE random_timestamp_between(rd.StartDate::TIMESTAMP, '2100-01-01'::TIMESTAMP)::DATE
    END as FinishDate
FROM RawData rd;

/*
  Затереть даты родителей, пересчитать на основе интервалов потомков как их объединение
*/
SELECT public.fn_refresh_parent_interval_dates();