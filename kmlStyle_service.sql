create service kmlStyle
type 'RAW'
authorization off user "dba"
url on
as call util.xml_for_http(dbo.kmlStyle(:url));
