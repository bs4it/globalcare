rem executar a partir de um CMD como administrator
echo Instalando Zabbix Agent 2 GlobalCare x64
C:\GlobalCare\bin\win64\zabbix_agent2.exe -c C:\GlobalCare\conf\zabbix_agent2.conf -i -m
echo Executando Zabbix Agent 2 GlobalCare x64
C:\GlobalCare\bin\win64\zabbix_agent2.exe -c C:\GlobalCare\conf\zabbix_agent2.conf -s -m
echo Regra de firewall permitindo porta zabbix
netsh advfirewall firewall add rule name="Zabbix Agent 2 GlobalCare" remoteip=127.0.0.1 dir=in action=allow protocol=TCP localport=10055
echo Regra de firewall permitindo ICMP do zabbix proxy
netsh advfirewall firewall add rule name="Zabbix Proxy GlobalCare ICMP" remoteip=127.0.0.1 protocol=icmpv4:any,any dir=in action=allow