# sql-portfolio
This one was created to show my skills in writing sql functions and stored procs

# Why
To show my ability to write understandable sql code (functions/triggers)
To show my ability to see performance bottlenecks (optimization progress could be seen at "Resolved problems" section)

# Resolved problems
- DateInterval.Type calculation moved to trigger "public.tg_dateinterval_type_func"

# TODO
- translate comments to English
- add trigger for "IsParent" column recalculation
- add trigger to provide summary interval dates changing, when child's was changed
- escape child-to-parent recursive selects by introducing auxiliary cache table with triggers
- add MSSQL part 
