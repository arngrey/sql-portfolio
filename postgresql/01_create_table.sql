DROP TABLE IF EXISTS public.DateInterval;

CREATE TABLE public.DateInterval (
  DateIntervalId BIGINT PRIMARY KEY,
  -- поле "Родитель" - id из этой же таблицы
  -- иерархическая таблица
  ParentId BIGINT REFERENCES DateInterval(DateIntervalId),
  -- является ли запись родительской (имеет ли потомков)
  IsParent BOOL NOT NULL,
  StartDate DATE NOT NULL,
  -- дата начала меньше или равна дате окончания
  FinishDate DATE NOT NULL CONSTRAINT check_start_lesser_or_equal_than_end CHECK (StartDate <= FinishDate),
  -- рассчетное поле, считается триггером "public.tg_dateinterval_type_func"
  Type VARCHAR NOT NULL CONSTRAINT check_available_types CHECK (Type =ANY(ARRAY['point', 'summary', 'interval'])) DEFAULT 'point'
);