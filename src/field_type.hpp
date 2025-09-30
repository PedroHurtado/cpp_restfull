#ifndef FIELD_TYPE_HPP
#define FIELD_TYPE_HPP

#include "field_validator.hpp"
#include "field_registry.hpp"
#include <memory>
#include <string>
#include <typeindex>
#include <iostream>

// Contexto para el registro
struct FieldRegistrationContext {
    std::type_index model_type;
    void* model_instance;
    bool active;
    
    FieldRegistrationContext(std::type_index type, void* instance)
        : model_type(type), model_instance(instance), active(true) {}
};

inline thread_local FieldRegistrationContext* current_context = nullptr;

// Field<T> como tipo que envuelve un valor
template<typename T>
class Field {
public:
    // Constructor con nombre del campo JSON y opciones
    Field(const std::string& json_field_name, typename FieldValidator<T>::Options options)
        : json_field_name_(json_field_name), value_() {
        
        // Crear validador
        validator_ = std::make_shared<FieldValidator<T>>(json_field_name, options);
        
        // Si hay valor por defecto, asignarlo
        if (options.default_val) {
            value_ = *options.default_val;
        }
        
        // NO registramos aquí - BaseModel lo hará después
    }
    
    // Constructor básico: solo required
    Field(const std::string& json_field_name, bool required = false)
        : Field(json_field_name, create_basic_options(required)) {}
    
    // Destructor
    ~Field() = default;
    
    // Conversión implícita a T (lectura)
    operator T() const {
        return value_;
    }
    
    // Conversión a referencia (modificación)
    operator T&() {
        return value_;
    }
    
    // Operador de asignación desde T
    Field& operator=(const T& value) {
        value_ = value;
        return *this;
    }
    
    // Acceso directo al valor
    T& value() {
        return value_;
    }
    
    const T& value() const {
        return value_;
    }
    
    // Validar este campo
    std::pair<bool, std::string> validate() const {
        return validator_->validate(value_);
    }
    
    // Obtener validador
    std::shared_ptr<FieldValidator<T>> get_validator() const {
        return validator_;
    }
    
    // Obtener nombre del campo
    std::string get_field_name() const {
        return json_field_name_;
    }
    
    // Registrar este campo en el registry (llamado por BaseModel)
    void register_in_registry(std::type_index model_type, size_t offset) {
        auto validate_fn = [](void* field_ptr) -> std::pair<bool, std::string> {
            Field<T>* field = static_cast<Field<T>*>(field_ptr);
            return field->validate();
        };
        
        FieldRegistry::instance().register_field(
            model_type,
            json_field_name_,
            validator_,
            offset,
            std::type_index(typeid(T)),
            validate_fn
        );
    }

private:
    std::string json_field_name_;
    T value_;
    std::shared_ptr<FieldValidator<T>> validator_;
    
    // Helper para crear opciones básicas
    static typename FieldValidator<T>::Options create_basic_options(bool required) {
        typename FieldValidator<T>::Options options;
        options.required = required;
        return options;
    }
};

// Operator << para imprimir Field<T> directamente
template<typename T>
std::ostream& operator<<(std::ostream& os, const Field<T>& field) {
    os << field.value();
    return os;
}

// Helpers para crear Fields con diferentes configuraciones

// String con longitudes
template<typename T>
typename std::enable_if<std::is_same<T, std::string>::value, Field<T>>::type
CreateField(const std::string& json_name, bool required, size_t min_len, size_t max_len) {
    typename FieldValidator<T>::Options opts;
    opts.required = required;
    opts.min_length = min_len;
    opts.max_length = max_len;
    return Field<T>(json_name, opts);
}

// Número con rango
template<typename T>
typename std::enable_if<std::is_arithmetic<T>::value, Field<T>>::type
CreateField(const std::string& json_name, bool required, T min_val, T max_val) {
    typename FieldValidator<T>::Options opts;
    opts.required = required;
    opts.min_value = min_val;
    opts.max_value = max_val;
    return Field<T>(json_name, opts);
}

// Con valor por defecto
template<typename T>
Field<T> CreateField(const std::string& json_name, T default_value) {
    typename FieldValidator<T>::Options opts;
    opts.required = false;
    opts.default_val = default_value;
    
    Field<T> field(json_name, opts);
    field = default_value;  // Asignar el valor por defecto
    return field;
}

// Con valores permitidos (enum)
template<typename T>
Field<T> CreateField(const std::string& json_name, bool required, const std::vector<T>& allowed) {
    typename FieldValidator<T>::Options opts;
    opts.required = required;
    opts.allowed_values = allowed;
    return Field<T>(json_name, opts);
}

#endif // FIELD_TYPE_HPP