/*
	Триггер для поддержания в согласованном состоянии поля Type:
	- если у интервала нулевая длительность, то 'point' - точка
	- если у интервала есть потомки, то 'summary' - суммарный
	- иначе 'interval' - обычный интервал
*/

CREATE OR REPLACE FUNCTION tg_dateinterval_type_func()
RETURNS TRIGGER 
LANGUAGE plpgsql
AS $$
BEGIN


	/* Изменение собственного типа */
	IF (TG_OP = 'INSERT') THEN
		/* Новый интервал суммарным быть не может */
		UPDATE DateInterval di
		SET Type = CASE 
			WHEN NEW.StartDate = NEW.FinishDate THEN 'point'
			ELSE 'interval'
		END
		WHERE di.DateIntervalId = NEW.DateIntervalId;		
	END IF;


	IF (TG_NAME = 'tg_dateinterval_type_upd_transform') THEN
		UPDATE DateInterval di
		SET Type = CASE
				WHEN EXISTS( 
					SELECT 1 
					FROM DateInterval dii
					WHERE dii.ParentId = NEW.DateIntervalId
				) THEN 'summary'		
				WHEN di.StartDate = di.FinishDate THEN 'point'
				ELSE 'interval'
		END
		WHERE di.DateIntervalId = NEW.DateIntervalId;
	END IF;

	
	/* Изменение типов родителя */
	IF (TG_OP = 'INSERT' OR TG_NAME = 'tg_dateinterval_type_upd_reparent') THEN
		/* Новый родитель точно стал этапом */
		UPDATE DateInterval di
		SET Type = 'summary'
		WHERE di.DateIntervalId = NEW.ParentId;
	END IF;

	
	IF (TG_OP = 'DELETE' OR TG_NAME = 'tg_dateinterval_type_upd_reparent') THEN
		/* Пересчитываем старого родителя */
		UPDATE DateInterval di
		SET Type = CASE 
			WHEN EXISTS( 
				SELECT 1 
				FROM DateInterval dii
				WHERE dii.ParentId = NEW.DateIntervalId
			) THEN 'summary'::text 		
			WHEN di.StartDate = di.FinishDate THEN 'point'::text 
			ELSE 'interval'::text 
		END
		WHERE di.DateIntervalId = OLD.ParentId;
		
	END IF;


   RETURN NULL;
END; $$;


CREATE TRIGGER tg_dateinterval_type_ins
AFTER INSERT ON DateInterval
FOR EACH ROW
EXECUTE PROCEDURE tg_dateinterval_type_func();

CREATE TRIGGER tg_dateinterval_type_upd_transform
AFTER UPDATE ON DateInterval
FOR EACH ROW
WHEN (
	/* Превратили интервал в точку */
	(NEW.StartDate = NEW.FinishDate AND OLD.StartDate != OLD.FinishDate)
	/* Превратили точку в интервал */
	OR (NEW.StartDate != NEW.FinishDate AND OLD.StartDate = OLD.FinishDate)
)
EXECUTE PROCEDURE tg_dateinterval_type_func();

CREATE TRIGGER tg_dateinterval_type_upd_reparent
AFTER UPDATE ON DateInterval
FOR EACH ROW
WHEN (
	/* Изменили дерево */
	NEW.ParentId IS DISTINCT FROM OLD.ParentId
)
EXECUTE PROCEDURE tg_dateinterval_type_func();

CREATE TRIGGER tg_dateinterval_type_del
AFTER DELETE on DateInterval
FOR EACH ROW
WHEN (
	/* У удаленного элемента есть родитель, на которого можно повлиять */
	OLD.ParentId IS NOT NULL
)
EXECUTE PROCEDURE tg_dateinterval_type_func();

