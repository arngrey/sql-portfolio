/* 
Пересчет дат родительских интервалов на основе интервалов дат потомков 
*/
CREATE OR REPLACE FUNCTION public.refreshParentIntervalDates ()
RETURNS VOID
LANGUAGE SQL
AS
$$


WITH RECURSIVE
DateIntervals AS (
	SELECT
		di.DateIntervalId,
		di.ParentId,
		di.IsParent,
		di.StartDate,
		di.FinishDate
	FROM DateInterval di
),

/*
Для каждого листа дерева рекурсивно вверх строится цепочка родителе
(Каждый родитель из цепочки дублируется для каждого листа)
*/
Parents AS (
	SELECT
		di.DateIntervalId,
		di.ParentId
	FROM DateInterval di
	WHERE NOT di.IsParent
		AND di.ParentId IS NOT NULL

	UNION ALL

	SELECT
		p.DateIntervalId,
		di.ParentId
	FROM DateInterval di
	INNER JOIN Parents p on p.ParentId = di.DateIntervalId
	WHERE di.ParentId IS NOT NULL
),

/*
Дублирование листа для каждого родителя из цепочки показывает влияние его дат.
*/
DateIntervalParents AS (
	SELECT
		diBran.PointId,
		diLeaf.StartDate,
		diLeaf.FinishDate
	FROM DateIntervals diLeaf
	INNER JOIN Parents p on p.DateIntervalId = diLeaf.DateIntervalId
	INNER JOIN DateIntervals diBran on diBran.DateIntervalId = p.ParentId
	WHERE NOT diLeaf.IsParent
		AND diBran.IsParent
),

/* 
Через Group By находится минимальная и максимальная даты для каждого родителя.
(Агрегирую влияние дат-листьев по каждому родителю, нахожу крайние даты)
*/
DateIntervalParentDates as (
	SELECT
		dip.DateIntervalId,
		min(dip.StartDate) as DateMin,
		max(dip.FinishDate) as DateMax
	FROM DateIntervalParents dip
	GROUP BY dip.DateIntervalId
),

UPDATE DateInterval di
SET
	StartDate = dipd.StartDate,
	FinishDate = dipd.FinishDate
FROM DateIntervalParentDates dipd
WHERE dipd.PointId = di.PointId
	AND (
		di.StartDate IS DISTINCT FROM dipd.StartDate OR
		di.FinishDate IS DISTINCT FROM dipd.FinishDate
	);

$$;
