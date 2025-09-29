# Serialización de Datos con JSON y XML

## ¿Qué es la Serialización?

La serialización es el proceso de convertir estructuras de datos u objetos en un formato que puede ser almacenado o transmitido y posteriormente reconstruido. En el contexto de servicios web, la serialización permite que datos complejos se conviertan en formatos estándar como JSON o XML para su intercambio entre sistemas.

```cpp
// Objeto C++
struct User {
    int id;
    std::string name;
    std::string email;
    std::vector<std::string> roles;
};

// Serialización
User user{123, "Juan Pérez", "juan@example.com", {"admin", "editor"}};
std::string json = serialize(user);  // → JSON string
std::string xml = serializeXML(user); // → XML string

// Deserialización
User reconstructed = deserialize<User>(json);
```

## JSON (JavaScript Object Notation)

### Características de JSON

#### 1. Sintaxis Ligera y Legible
```json
{
  "id": 123,
  "name": "Juan Pérez",
  "email": "juan@example.com",
  "active": true,
  "balance": 1234.56,
  "roles": ["admin", "editor"],
  "preferences": {
    "theme": "dark",
    "language": "es",
    "notifications": true
  },
  "last_login": null
}
```

#### 2. Tipos de Datos Soportados
- **String**: Cadenas de texto UTF-8
- **Number**: Enteros y decimales
- **Boolean**: true/false
- **null**: Valor nulo
- **Object**: Colecciones clave-valor
- **Array**: Listas ordenadas

#### 3. Independiente del Lenguaje
JSON es un formato de intercambio de datos independiente del lenguaje, aunque derivado de JavaScript.

### Implementación JSON en C++

#### Usando nlohmann/json
```cpp
#include <nlohmann/json.hpp>
#include <iostream>
#include <vector>
#include <fstream>

using json = nlohmann::json;

class JSONHandler {
public:
    // Serialización básica
    static std::string serializeUser(const User& user) {
        json j;
        j["id"] = user.id;
        j["name"] = user.name;
        j["email"] = user.email;
        j["active"] = user.active;
        j["balance"] = user.balance;
        j["roles"] = user.roles;
        j["created_at"] = user.createdAt;
        
        // Objeto anidado
        j["preferences"]["theme"] = user.preferences.theme;
        j["preferences"]["language"] = user.preferences.language;
        j["preferences"]["notifications"] = user.preferences.notifications;
        
        return j.dump(4); // Pretty print con indentación
    }
    
    // Deserialización básica
    static User deserializeUser(const std::string& jsonStr) {
        json j = json::parse(jsonStr);
        
        User user;
        user.id = j["id"];
        user.name = j["name"];
        user.email = j["email"];
        user.active = j.value("active", true); // Valor por defecto
        user.balance = j.value("balance", 0.0);
        
        // Manejo seguro de arrays
        if (j.contains("roles") && j["roles"].is_array()) {
            user.roles = j["roles"].get<std::vector<std::string>>();
        }
        
        // Manejo de objetos anidados
        if (j.contains("preferences")) {
            user.preferences.theme = j["preferences"].value("theme", "light");
            user.preferences.language = j["preferences"].value("language", "en");
            user.preferences.notifications = j["preferences"].value("notifications", true);
        }
        
        return user;
    }
};
```

#### Serialización Automática con Macros
```cpp
#include <nlohmann/json.hpp>

struct User {
    int id;
    std::string name;
    std::string email;
    bool active;
    double balance;
    std::vector<std::string> roles;
    
    // Macro para serialización automática
    NLOHMANN_DEFINE_TYPE_INTRUSIVE(User, id, name, email, active, balance, roles)
};

// Uso simplificado
void example() {
    User user{123, "Juan", "juan@example.com", true, 1500.75, {"admin", "user"}};
    
    // Serialización automática
    json j = user;
    std::string jsonStr = j.dump();
    
    // Deserialización automática
    User reconstructed = j.get<User>();
}
```

#### Manejo de Errores en JSON
```cpp
class SafeJSONParser {
public:
    static std::optional<User> parseUser(const std::string& jsonStr) {
        try {
            json j = json::parse(jsonStr);
            
            // Validación de schema
            if (!validateUserSchema(j)) {
                std::cerr << "Invalid user schema" << std::endl;
                return std::nullopt;
            }
            
            User user;
            user.id = j["id"];
            user.name = j["name"];
            user.email = j["email"];
            
            // Validación de datos
            if (user.id <= 0) {
                std::cerr << "Invalid user ID" << std::endl;
                return std::nullopt;
            }
            
            if (!isValidEmail(user.email)) {
                std::cerr << "Invalid email format" << std::endl;
                return std::nullopt;
            }
            
            return user;
            
        } catch (const json::parse_error& e) {
            std::cerr << "JSON parse error: " << e.what() << std::endl;
            return std::nullopt;
        } catch (const json::type_error& e) {
            std::cerr << "JSON type error: " << e.what() << std::endl;
            return std::nullopt;
        }
    }
    
private:
    static bool validateUserSchema(const json& j) {
        return j.contains("id") && j["id"].is_number_integer() &&
               j.contains("name") && j["name"].is_string() &&
               j.contains("email") && j["email"].is_string();
    }
    
    static bool isValidEmail(const std::string& email) {
        std::regex pattern(R"(\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b)");
        return std::regex_match(email, pattern);
    }
};
```

#### JSON Streaming para Archivos Grandes
```cpp
class JSONStreamer {
public:
    // Lectura streaming de arrays grandes
    static void processLargeJSONArray(const std::string& filename) {
        std::ifstream file(filename);
        json j;
        
        try {
            file >> j;
            
            if (j.is_array()) {
                for (auto& element : j) {
                    processJSONObject(element);
                }
            }
        } catch (const json::parse_error& e) {
            std::cerr << "Error processing large JSON: " << e.what() << std::endl;
        }
    }
    
    // Escritura streaming
    static void writeJSONStream(const std::string& filename, 
                               const std::vector<User>& users) {
        std::ofstream file(filename);
        
        file << "[\n";
        for (size_t i = 0; i < users.size(); ++i) {
            json userJson = users[i];
            file << userJson.dump(2);
            
            if (i < users.size() - 1) {
                file << ",\n";
            }
        }
        file << "\n]";
    }
    
private:
    static void processJSONObject(const json& obj) {
        // Procesar cada objeto individualmente
        if (obj.contains("id")) {
            int id = obj["id"];
            std::cout << "Processing user ID: " << id << std::endl;
        }
    }
};
```

#### JSON Schema Validation
```cpp
class JSONValidator {
private:
    json userSchema = R"({
        "type": "object",
        "properties": {
            "id": {"type": "integer", "minimum": 1},
            "name": {"type": "string", "minLength": 1, "maxLength": 100},
            "email": {"type": "string", "format": "email"},
            "active": {"type": "boolean"},
            "balance": {"type": "number", "minimum": 0},
            "roles": {
                "type": "array",
                "items": {"type": "string"},
                "uniqueItems": true
            }
        },
        "required": ["id", "name", "email"],
        "additionalProperties": false
    })"_json;
    
public:
    bool validateUser(const json& userData) {
        return validateAgainstSchema(userData, userSchema);
    }
    
private:
    bool validateAgainstSchema(const json& data, const json& schema) {
        // Implementación básica de validación
        if (schema["type"] == "object") {
            if (!data.is_object()) return false;
            
            // Verificar propiedades requeridas
            if (schema.contains("required")) {
                for (const auto& prop : schema["required"]) {
                    if (!data.contains(prop)) return false;
                }
            }
            
            // Verificar tipos de propiedades
            if (schema.contains("properties")) {
                for (auto& [key, propSchema] : schema["properties"].items()) {
                    if (data.contains(key)) {
                        if (!validateAgainstSchema(data[key], propSchema)) {
                            return false;
                        }
                    }
                }
            }
        }
        
        return true;
    }
};
```

## XML (eXtensible Markup Language)

### Características de XML

#### 1. Estructura Jerárquica
```xml
<?xml version="1.0" encoding="UTF-8"?>
<user xmlns="http://example.com/user" xmlns:pref="http://example.com/preferences">
    <id>123</id>
    <name>Juan Pérez</name>
    <email>juan@example.com</email>
    <active>true</active>
    <balance currency="USD">1234.56</balance>
    
    <roles>
        <role>admin</role>
        <role>editor</role>
    </roles>
    
    <pref:preferences>
        <pref:theme>dark</pref:theme>
        <pref:language>es</pref:language>
        <pref:notifications enabled="true"/>
    </pref:preferences>
    
    <metadata>
        <created_at>2025-09-28T10:00:00Z</created_at>
        <last_modified>2025-09-28T15:30:00Z</last_modified>
    </metadata>
</user>
```

#### 2. Namespaces y Atributos
XML soporta namespaces para evitar conflictos de nombres y atributos para metadatos.

#### 3. Validación con Schemas
```xml
<!-- XML Schema Definition (XSD) -->
<xs:schema xmlns:xs="http://www.w3.org/2001/XMLSchema"
           targetNamespace="http://example.com/user">
    
    <xs:element name="user">
        <xs:complexType>
            <xs:sequence>
                <xs:element name="id" type="xs:positiveInteger"/>
                <xs:element name="name" type="xs:string"/>
                <xs:element name="email" type="xs:string"/>
                <xs:element name="active" type="xs:boolean"/>
                <xs:element name="balance" type="xs:decimal"/>
                <xs:element name="roles" type="RolesType"/>
            </xs:sequence>
        </xs:complexType>
    </xs:element>
    
    <xs:complexType name="RolesType">
        <xs:sequence>
            <xs:element name="role" type="xs:string" maxOccurs="unbounded"/>
        </xs:sequence>
    </xs:complexType>
    
</xs:schema>
```

### Implementación XML en C++

#### Usando TinyXML2
```cpp
#include <tinyxml2.h>
#include <iostream>
#include <vector>
#include <string>

using namespace tinyxml2;

class XMLHandler {
public:
    // Serialización a XML
    static std::string serializeUser(const User& user) {
        XMLDocument doc;
        
        // Declaración XML
        auto declaration = doc.NewDeclaration("xml version=\"1.0\" encoding=\"UTF-8\"");
        doc.InsertFirstChild(declaration);
        
        // Elemento raíz
        auto userElement = doc.NewElement("user");
        doc.InsertEndChild(userElement);
        
        // Elementos básicos
        auto idElement = doc.NewElement("id");
        idElement->SetText(user.id);
        userElement->InsertEndChild(idElement);
        
        auto nameElement = doc.NewElement("name");
        nameElement->SetText(user.name.c_str());
        userElement->InsertEndChild(nameElement);
        
        auto emailElement = doc.NewElement("email");
        emailElement->SetText(user.email.c_str());
        userElement->InsertEndChild(emailElement);
        
        auto activeElement = doc.NewElement("active");
        activeElement->SetText(user.active);
        userElement->InsertEndChild(activeElement);
        
        // Elemento con atributo
        auto balanceElement = doc.NewElement("balance");
        balanceElement->SetAttribute("currency", "USD");
        balanceElement->SetText(user.balance);
        userElement->InsertEndChild(balanceElement);
        
        // Array de roles
        auto rolesElement = doc.NewElement("roles");
        userElement->InsertEndChild(rolesElement);
        
        for (const auto& role : user.roles) {
            auto roleElement = doc.NewElement("role");
            roleElement->SetText(role.c_str());
            rolesElement->InsertEndChild(roleElement);
        }
        
        // Objeto anidado con namespace
        auto preferencesElement = doc.NewElement("preferences");
        preferencesElement->SetAttribute("xmlns", "http://example.com/preferences");
        userElement->InsertEndChild(preferencesElement);
        
        auto themeElement = doc.NewElement("theme");
        themeElement->SetText(user.preferences.theme.c_str());
        preferencesElement->InsertEndChild(themeElement);
        
        auto languageElement = doc.NewElement("language");
        languageElement->SetText(user.preferences.language.c_str());
        preferencesElement->InsertEndChild(languageElement);
        
        auto notificationsElement = doc.NewElement("notifications");
        notificationsElement->SetAttribute("enabled", user.preferences.notifications);
        preferencesElement->InsertEndChild(notificationsElement);
        
        // Convertir a string
        XMLPrinter printer;
        doc.Print(&printer);
        return printer.CStr();
    }
    
    // Deserialización desde XML
    static std::optional<User> deserializeUser(const std::string& xmlStr) {
        XMLDocument doc;
        XMLError result = doc.Parse(xmlStr.c_str());
        
        if (result != XML_SUCCESS) {
            std::cerr << "XML Parse Error: " << result << std::endl;
            return std::nullopt;
        }
        
        auto userElement = doc.FirstChildElement("user");
        if (!userElement) {
            std::cerr << "Missing user element" << std::endl;
            return std::nullopt;
        }
        
        User user;
        
        // Elementos básicos con validación
        auto idElement = userElement->FirstChildElement("id");
        if (idElement) {
            user.id = idElement->IntText();
        } else {
            std::cerr << "Missing required id element" << std::endl;
            return std::nullopt;
        }
        
        auto nameElement = userElement->FirstChildElement("name");
        if (nameElement && nameElement->GetText()) {
            user.name = nameElement->GetText();
        }
        
        auto emailElement = userElement->FirstChildElement("email");
        if (emailElement && emailElement->GetText()) {
            user.email = emailElement->GetText();
        }
        
        auto activeElement = userElement->FirstChildElement("active");
        if (activeElement) {
            user.active = activeElement->BoolText();
        }
        
        auto balanceElement = userElement->FirstChildElement("balance");
        if (balanceElement) {
            user.balance = balanceElement->DoubleText();
            
            // Leer atributo
            const char* currency = balanceElement->Attribute("currency");
            if (currency) {
                user.currency = currency;
            }
        }
        
        // Procesar array de roles
        auto rolesElement = userElement->FirstChildElement("roles");
        if (rolesElement) {
            for (auto roleElement = rolesElement->FirstChildElement("role");
                 roleElement; 
                 roleElement = roleElement->NextSiblingElement("role")) {
                
                if (roleElement->GetText()) {
                    user.roles.push_back(roleElement->GetText());
                }
            }
        }
        
        // Procesar objeto anidado
        auto preferencesElement = userElement->FirstChildElement("preferences");
        if (preferencesElement) {
            auto themeElement = preferencesElement->FirstChildElement("theme");
            if (themeElement && themeElement->GetText()) {
                user.preferences.theme = themeElement->GetText();
            }
            
            auto languageElement = preferencesElement->FirstChildElement("language");
            if (languageElement && languageElement->GetText()) {
                user.preferences.language = languageElement->GetText();
            }
            
            auto notificationsElement = preferencesElement->FirstChildElement("notifications");
            if (notificationsElement) {
                user.preferences.notifications = notificationsElement->BoolAttribute("enabled");
            }
        }
        
        return user;
    }
};
```

#### XML con Validación de Schema
```cpp
#include <libxml/parser.h>
#include <libxml/xmlschemas.h>

class XMLValidator {
private:
    xmlSchemaPtr schema;
    xmlSchemaValidCtxtPtr validationContext;
    
public:
    XMLValidator(const std::string& schemaFile) {
        // Inicializar libxml2
        xmlInitParser();
        
        // Cargar schema XSD
        xmlSchemaParserCtxtPtr parserContext = xmlSchemaNewParserCtxt(schemaFile.c_str());
        schema = xmlSchemaParse(parserContext);
        xmlSchemaFreeParserCtxt(parserContext);
        
        if (schema) {
            validationContext = xmlSchemaNewValidCtxt(schema);
        }
    }
    
    bool validateXML(const std::string& xmlContent) {
        if (!schema || !validationContext) {
            return false;
        }
        
        xmlDocPtr doc = xmlParseMemory(xmlContent.c_str(), xmlContent.length());
        if (!doc) {
            return false;
        }
        
        int result = xmlSchemaValidateDoc(validationContext, doc);
        
        xmlFreeDoc(doc);
        return result == 0;
    }
    
    ~XMLValidator() {
        if (validationContext) xmlSchemaFreeValidCtxt(validationContext);
        if (schema) xmlSchemaFree(schema);
        xmlCleanupParser();
    }
};
```

#### XSLT Transformations
```cpp
#include <libxslt/xslt.h>
#include <libxslt/transform.h>

class XSLTProcessor {
public:
    static std::string transformXML(const std::string& xmlContent, 
                                   const std::string& xsltContent) {
        // Parsear XML
        xmlDocPtr xmlDoc = xmlParseMemory(xmlContent.c_str(), xmlContent.length());
        if (!xmlDoc) {
            throw std::runtime_error("Failed to parse XML");
        }
        
        // Parsear XSLT
        xmlDocPtr xsltDoc = xmlParseMemory(xsltContent.c_str(), xsltContent.length());
        if (!xsltDoc) {
            xmlFreeDoc(xmlDoc);
            throw std::runtime_error("Failed to parse XSLT");
        }
        
        // Crear stylesheet
        xsltStylesheetPtr stylesheet = xsltParseStylesheetDoc(xsltDoc);
        if (!stylesheet) {
            xmlFreeDoc(xmlDoc);
            xmlFreeDoc(xsltDoc);
            throw std::runtime_error("Failed to parse XSLT stylesheet");
        }
        
        // Aplicar transformación
        xmlDocPtr resultDoc = xsltApplyStylesheet(stylesheet, xmlDoc, nullptr);
        if (!resultDoc) {
            xsltFreeStylesheet(stylesheet);
            xmlFreeDoc(xmlDoc);
            throw std::runtime_error("XSLT transformation failed");
        }
        
        // Convertir resultado a string
        xmlChar* resultString;
        int resultLength;
        xsltSaveResultToString(&resultString, &resultLength, resultDoc, stylesheet);
        
        std::string result(reinterpret_cast<char*>(resultString));
        
        // Limpiar memoria
        xmlFree(resultString);
        xmlFreeDoc(resultDoc);
        xsltFreeStylesheet(stylesheet);
        xmlFreeDoc(xmlDoc);
        
        return result;
    }
};

// Ejemplo de uso
void exampleXSLT() {
    std::string xml = R"(
        <users>
            <user id="1"><name>Juan</name></user>
            <user id="2"><name>María</name></user>
        </users>
    )";
    
    std::string xslt = R"(
        <xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
            <xsl:template match="/">
                <html>
                    <body>
                        <h1>Users List</h1>
                        <ul>
                            <xsl:for-each select="users/user">
                                <li><xsl:value-of select="name"/></li>
                            </xsl:for-each>
                        </ul>
                    </body>
                </html>
            </xsl:template>
        </xsl:stylesheet>
    )";
    
    std::string html = XSLTProcessor::transformXML(xml, xslt);
    std::cout << html << std::endl;
}
```

## Comparación JSON vs XML

### Tabla Comparativa

| Aspecto | JSON | XML |
|---------|------|-----|
| **Sintaxis** | Ligera, menos verbosa | Verbosa, más descriptiva |
| **Tamaño** | Menor (~30% menos) | Mayor |
| **Parsing** | Más rápido | Más lento |
| **Tipos de datos** | Limitados (6 tipos) | Flexible con schemas |
| **Namespaces** | No | Sí |
| **Atributos** | No | Sí |
| **Comentarios** | No | Sí |
| **Validación** | JSON Schema | XSD, DTD, RelaxNG |
| **Transformación** | Limitada | XSLT |
| **Legibilidad** | Alta | Media |
| **Soporte navegadores** | Nativo | Nativo |

### Comparación de Rendimiento

```cpp
#include <chrono>

class PerformanceComparison {
public:
    static void compareSerializationPerformance() {
        std::vector<User> users = generateLargeUserDataset(10000);
        
        // Benchmark JSON
        auto start = std::chrono::high_resolution_clock::now();
        std::string jsonResult = serializeUsersToJSON(users);
        auto jsonTime = std::chrono::high_resolution_clock::now() - start;
        
        // Benchmark XML
        start = std::chrono::high_resolution_clock::now();
        std::string xmlResult = serializeUsersToXML(users);
        auto xmlTime = std::chrono::high_resolution_clock::now() - start;
        
        std::cout << "JSON Serialization: " 
                  << std::chrono::duration_cast<std::chrono::milliseconds>(jsonTime).count() 
                  << "ms" << std::endl;
        std::cout << "XML Serialization: " 
                  << std::chrono::duration_cast<std::chrono::milliseconds>(xmlTime).count() 
                  << "ms" << std::endl;
        
        std::cout << "JSON size: " << jsonResult.size() << " bytes" << std::endl;
        std::cout << "XML size: " << xmlResult.size() << " bytes" << std::endl;
    }
    
private:
    static std::string serializeUsersToJSON(const std::vector<User>& users) {
        json j = json::array();
        for (const auto& user : users) {
            j.push_back(user);
        }
        return j.dump();
    }
    
    static std::string serializeUsersToXML(const std::vector<User>& users) {
        XMLDocument doc;
        auto root = doc.NewElement("users");
        doc.InsertEndChild(root);
        
        for (const auto& user : users) {
            auto userElement = doc.NewElement("user");
            // ... serialización de cada usuario
            root->InsertEndChild(userElement);
        }
        
        XMLPrinter printer;
        doc.Print(&printer);
        return printer.CStr();
    }
};
```

## Casos de Uso Específicos

### JSON es Mejor Para:

#### APIs REST y Servicios Web Modernos
```cpp
// API Response típica
{
  "data": [
    {
      "id": 123,
      "name": "Producto A",
      "price": 29.99,
      "category": "electronics"
    }
  ],
  "pagination": {
    "page": 1,
    "limit": 20,
    "total": 150
  },
  "meta": {
    "request_id": "req_123456",
    "timestamp": "2025-09-28T10:00:00Z"
  }
}
```

#### Configuración de Aplicaciones
```cpp
class ConfigManager {
public:
    static Config loadFromJSON(const std::string& filename) {
        std::ifstream file(filename);
        json config;
        file >> config;
        
        Config result;
        result.serverPort = config.value("server_port", 8080);
        result.dbHost = config.value("db_host", "localhost");
        result.logLevel = config.value("log_level", "info");
        result.features = config.value("features", json::object());
        
        return result;
    }
};
```

#### Intercambio de Datos con JavaScript/Frontend
```cpp
// Perfect for AJAX responses
void sendUserData(Http::ResponseWriter& response, const User& user) {
    json userData = {
        {"id", user.id},
        {"name", user.name},
        {"email", user.email},
        {"permissions", user.roles}
    };
    
    response.headers().add<Http::Header::ContentType>(MIME(Application, Json));
    response.send(Http::Code::Ok, userData.dump());
}
```

### XML es Mejor Para:

#### Documentos Complejos con Metadata
```xml
<document xmlns="http://company.com/documents" 
          xmlns:author="http://company.com/authors"
          version="2.1" 
          classification="confidential">
    
    <metadata>
        <author:info id="emp123">
            <author:name>Juan Pérez</author:name>
            <author:department>Engineering</author:department>
            <author:clearance level="5"/>
        </author:info>
        <created>2025-09-28T10:00:00Z</created>
        <last_modified by="emp456">2025-09-28T15:30:00Z</last_modified>
    </metadata>
    
    <content>
        <section title="Overview" security="public">
            <paragraph>This document contains...</paragraph>
        </section>
        <section title="Technical Details" security="restricted">
            <!-- Content with mixed data and attributes -->
        </section>
    </content>
    
</document>
```

#### Configuración Empresarial Compleja
```cpp
class XMLConfigManager {
public:
    struct DatabaseConfig {
        std::string host;
        int port;
        std::string database;
        bool ssl;
        int timeout;
    };
    
    static DatabaseConfig parseDBConfig(const std::string& xmlFile) {
        XMLDocument doc;
        doc.LoadFile(xmlFile.c_str());
        
        auto dbElement = doc.FirstChildElement("configuration")
                           ->FirstChildElement("database");
        
        DatabaseConfig config;
        config.host = dbElement->Attribute("host");
        config.port = dbElement->IntAttribute("port");
        config.ssl = dbElement->BoolAttribute("ssl", false);
        config.timeout = dbElement->IntAttribute("timeout", 30);
        
        auto dbNameElement = dbElement->FirstChildElement("database_name");
        config.database = dbNameElement->GetText();
        
        return config;
    }
};
```

#### Integración con Sistemas Legacy
```cpp
// Muchos sistemas empresariales antiguos usan XML
class LegacySystemIntegration {
public:
    std::string generateSOAPRequest(const OrderRequest& order) {
        XMLDocument doc;
        
        // SOAP Envelope
        auto envelope = doc.NewElement("soap:Envelope");
        envelope->SetAttribute("xmlns:soap", "http://schemas.xmlsoap.org/soap/envelope/");
        doc.InsertEndChild(envelope);
        
        auto body = doc.NewElement("soap:Body");
        envelope->InsertEndChild(body);
        
        // Business data
        auto orderElement = doc.NewElement("CreateOrder");
        orderElement->SetAttribute("xmlns", "http://legacy-system.com/orders");
        body->InsertEndChild(orderElement);
        
        // ... construir XML detallado para el sistema legacy
        
        XMLPrinter printer;
        doc.Print(&printer);
        return printer.CStr();
    }
};
```

## Optimización de Rendimiento

### JSON Streaming para Grandes Volúmenes
```cpp
class JSONStreamProcessor {
public:
    // Procesar JSON línea por línea (NDJSON)
    static void processLargeJSONLines(const std::string& filename) {
        std::ifstream file(filename);
        std::string line;
        
        while (std::getline(file, line)) {
            if (!line.empty()) {
                try {
                    json obj = json::parse(line);
                    processObject(obj);
                } catch (const json::parse_error& e) {
                    std::cerr << "Parse error in line: " << e.what() << std::endl;
                }
            }
        }
    }
    
    // Generar JSON streaming
    static void writeJSONStream(const std::string& filename, 
                               std::function<User()> userGenerator,
                               size_t count) {
        std::ofstream file(filename);
        
        for (size_t i = 0; i < count; ++i) {
            User user = userGenerator();
            json userJson = user;
            file << userJson.dump() << "\n";
        }
    }
    
private:
    static void processObject(const json& obj) {
        // Procesar objeto individual
        if (obj.contains("id")) {
            int id = obj["id"];
            // Procesar...
        }
    }
};
```

### XML SAX Parsing para Memoria Limitada
```cpp
#include <libxml/parser.h>
#include <libxml/SAX2.h>

class SAXUserHandler {
private:
    std::vector<User> users;
    User currentUser;
    std::string currentElement;
    
public:
    static void startElement(void* ctx, const xmlChar* name, const xmlChar** attrs) {
        SAXUserHandler* handler = static_cast<SAXUserHandler*>(ctx);
        handler->currentElement = reinterpret_cast<const char*>(name);
        
        if (handler->currentElement == "user") {
            handler->currentUser = User(); // Reset
        }
    }
    
    static void characters(void* ctx, const xmlChar* ch, int len) {
        SAXUserHandler* handler = static_cast<SAXUserHandler*>(ctx);
        std::string content(reinterpret_cast<const char*>(ch), len);
        
        if (handler->currentElement == "id") {
            handler->currentUser.id = std::stoi(content);
        } else if (handler->currentElement == "name") {
            handler->currentUser.name = content;
        } else if (handler->currentElement == "email") {
            handler->currentUser.email = content;
        }
    }
    
    static void endElement(void* ctx, const xmlChar* name) {
        SAXUserHandler* handler = static_cast<SAXUserHandler*>(ctx);
        
        if (std::string(reinterpret_cast<const char*>(name)) == "user") {
            handler->users.push_back(handler->currentUser);
        }
    }
    
    std::vector<User> parseXMLFile(const std::string& filename) {
        xmlSAXHandler saxHandler = {};
        saxHandler.startElement = startElement;
        saxHandler.characters = characters;
        saxHandler.endElement = endElement;
        
        xmlSAXUserParseFile(&saxHandler, this, filename.c_str());
        
        return users;
    }
};
```

## Seguridad en Serialización

### Validación de Entrada
```cpp
class SecureDeserializer {
public:
    static std::optional<User> safeDeserializeUser(const std::string& input) {
        // Límite de tamaño
        if (input.size() > MAX_INPUT_SIZE) {
            std::cerr << "Input too large" << std::endl;
            return std::nullopt;
        }
        
        try {
            json j = json::parse(input);
            
            // Validar estructura
            if (!isValidUserStructure(j)) {
                return std::nullopt;
            }
            
            // Sanitizar strings
            User user;
            user.id = j["id"];
            user.name = sanitizeString(j["name"]);
            user.email = sanitizeEmail(j["email"]);
            
            return user;
            
        } catch (const json::parse_error& e) {
            std::cerr << "Parse error: " << e.what() << std::endl;
            return std::nullopt;
        }
    }
    
private:
    static constexpr size_t MAX_INPUT_SIZE = 1024 * 1024; // 1MB
    
    static bool isValidUserStructure(const json& j) {
        return j.is_object() &&
               j.contains("id") && j["id"].is_number_integer() &&
               j.contains("name") && j["name"].is_string() &&
               j.contains("email") && j["email"].is_string();
    }
    
    static std::string sanitizeString(const std::string& input) {
        std::string sanitized;
        for (char c : input) {
            if (std::isprint(c) && c != '<' && c != '>' && c != '&') {
                sanitized += c;
            }
        }
        return sanitized;
    }
    
    static std::string sanitizeEmail(const std::string& email) {
        std::regex emailPattern(R"(\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b)");
        if (std::regex_match(email, emailPattern)) {
            return email;
        }
        return "";
    }
};
```

### Prevención de Ataques XML
```cpp
class SecureXMLParser {
public:
    static std::optional<User> safeParseUser(const std::string& xmlContent) {
        // Configurar parser seguro
        XMLDocument doc;
        
        // Deshabilitar entidades externas (prevenir XXE)
        doc.SetEntityResolver([](const char*, const char*) {
            return nullptr; // Bloquear todas las entidades externas
        });
        
        XMLError result = doc.Parse(xmlContent.c_str());
        if (result != XML_SUCCESS) {
            return std::nullopt;
        }
        
        // Validar profundidad máxima
        if (getXMLDepth(doc.RootElement()) > MAX_XML_DEPTH) {
            std::cerr << "XML too deep" << std::endl;
            return std::nullopt;
        }
        
        return parseUserElement(doc.RootElement());
    }
    
private:
    static constexpr int MAX_XML_DEPTH = 10;
    
    static int getXMLDepth(const XMLElement* element, int currentDepth = 0) {
        if (!element) return currentDepth;
        
        int maxDepth = currentDepth;
        for (auto child = element->FirstChildElement(); 
             child; 
             child = child->NextSiblingElement()) {
            maxDepth = std::max(maxDepth, getXMLDepth(child, currentDepth + 1));
        }
        
        return maxDepth;
    }
};
```

## Conclusiones

La elección entre JSON y XML depende de varios factores:

**Usa JSON cuando:**
- ✅ Desarrolles APIs REST modernas
- ✅ La velocidad y eficiencia sean prioritarias
- ✅ Integres con aplicaciones web/JavaScript
- ✅ Manejes configuraciones simples
- ✅ El tamaño de los datos sea importante

**Usa XML cuando:**
- ✅ Necesites metadata compleja y atributos
- ✅ Requieras validación estricta con schemas
- ✅ Integres con sistemas empresariales legacy
- ✅ Manejes documentos complejos con namespaces
- ✅ Necesites transformaciones XSLT

En servicios web modernos en C++, JSON es generalmente la elección preferida por su simplicidad, rendimiento y amplio soporte. Sin embargo, XML sigue siendo relevante en contextos empresariales y sistemas que requieren estructura y validación complejas.