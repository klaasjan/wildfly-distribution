# WildFly - Java EE7 Full & Web Distribution

### HOW TO BUILD:
```
 > docker build -t wildfly-dist .
 > docker create --name wildfly-dist-cont wildfly-dist
 > docker cp wildfly-dist-cont:/tmp/wildfly-10.1.0.Final.topicus<version>.tar.gz ./
```
