# ==========================================
# Dockerfile para maku_repair (Java / Servlets / WAR)
# ==========================================

# Imagen oficial de Tomcat 10.1 con Java 17 (soporta Jakarta EE 10 / Jakarta Servlets)
FROM tomcat:10.1-jdk17

# 1. Limpiar las aplicaciones por defecto de Tomcat en webapps
RUN rm -rf /usr/local/tomcat/webapps/*

# 2. Copiar el archivo empaquetado .war directamente como ROOT.war
#    Esto montará tu aplicación en la raíz de la URL (https://tu-app.up.railway.app/)
COPY maku_repair.war /usr/local/tomcat/webapps/ROOT.war

# 3. Exponer el puerto por defecto de Tomcat
EXPOSE 8080

# 4. Iniciar Tomcat
CMD ["catalina.sh", "run"]
