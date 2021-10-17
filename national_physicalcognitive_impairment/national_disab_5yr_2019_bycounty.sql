
---------------------------------------------------------------------
-- Select impaired/non-impaired, aged 18 to 64, aggregated by county,
-- from American Community Survey 5-year summary acs2019_5yr
---------------------------------------------------------------------

drop table if exists disability_national_5yr_2019_bycounty;
create table disability_national_5yr_2019_bycounty as
with counts as (
  select 
    c15.full_geoid as c15_full_geoid, 
    c15.display_name as c15_display_name, 
    st_astext(c15.geom) as c15_geom_wkt,
    c15.geom as c15_geom,
	
    b19.b18101010 + b19.b18101029 + b19.b18101013 + b19.b18101032 + b19.b18101016 + b19.b18101035 + b19.b18101019 + b19.b18101038 as disab_18to64_num,
    b19.b18101011 + b19.b18101030 + b19.b18101014 + b19.b18101033 + b19.b18101017 + b19.b18101036 + b19.b18101020 + b19.b18101039 as nodisab_18to64_num

    from acs2019_5yr.b18101 b19
      inner join tiger2015.census_name_lookup c15
        on c15.full_geoid = b19.geoid
    where c15.sumlevel = '050' -- Summary level 050: County
)
select c15_full_geoid,
  c15_display_name,
  c15_geom_wkt,
  100.0 * disab_18to64_num::float / (disab_18to64_num + nodisab_18to64_num) as perc_18to64_disab
from counts
where disab_18to64_num is not null
  and nodisab_18to64_num is not null
  and disab_18to64_num + nodisab_18to64_num != 0
  and ST_Contains(ST_GeomFromText('POLYGON((-125 24, -125 50, -66 50, -66 24, -125 24))', 4326), c15_geom); -- Continental US region
  
-- Write to csv
\copy disability_national_5yr_2019_bycounty TO '/temp/disability_national_5yr_2019_bycounty.csv' WITH (FORMAT CSV, HEADER TRUE, FORCE_QUOTE *)

