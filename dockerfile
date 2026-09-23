# ==========================================
# Dockerfile para maku_repair (Java / JSP / Servlets)
# ==========================================

# Opción A: Despliegue directos de webapps en Tomcat (si ya tienes los compilados en WEB-INF/classes o compiled)
FROM tomcat:10.1-jdk17

# Eliminar la app por defecto ROOT de tomcat
RUN rm -rf /usr/local/tomcat/webapps/ROOT

# Copiar el contenido del directorio web del proyecto como la aplicación principal
COPY maku_repair/web/ /usr/local/tomcat/webapps/ROOT/

# Si tienes librerías externas o JARs compilados, copiar a WEB-INF/lib (si aplica)
# COPY maku_repair/build/web/WEB-INF/lib/ /usr/local/tomcat/webapps/ROOT/WEB-INF/lib/

# Exponer puerto por defecto de Tomcat
EXPOSE 8080

# Comando por defecto
CMD ["catalina.sh", "run"]
