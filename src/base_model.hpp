#ifndef BASE_MODEL_HPP
#define BASE_MODEL_HPP

#include "field_type.hpp"
#include "field_validator.hpp"
#include "field_registry.hpp"
#include <typeindex>
#include <vector>
#include <string>
#include <memory>

// Flag para evitar recursión durante el registro
inline thread_local bool in_registration = false;

// BaseModel usando CRTP
template<typename Derived>
class BaseModel {
public:
    BaseModel() {
        if (!in_registration) {
            ensure_fields_registered();
        }
    }

    virtual ~BaseModel() = default;

    // Validar todos los campos
    std::pair<bool, std::vector<std::string>> validate() {
        ensure_fields_registered();
        
        std::vector<std::string> errors;
        auto& registry = FieldRegistry::instance();
        const auto& fields = registry.get_fields(std::type_index(typeid(Derived)));
        
        for (const auto& field_info : fields) {
            void* field_ptr = reinterpret_cast<char*>(this) + field_info.offset;
            
            if (field_info.validate_func) {
                auto [valid, error] = field_info.validate_func(field_ptr);
                if (!valid) {
                    errors.push_back(error);
                }
            }
        }
        
        auto custom_errors = custom_validate();
        errors.insert(errors.end(), custom_errors.begin(), custom_errors.end());
        
        return {errors.empty(), errors};
    }

    const std::vector<FieldInfo>& get_fields() const {
        ensure_fields_registered();
        auto& registry = FieldRegistry::instance();
        return registry.get_fields(std::type_index(typeid(Derived)));
    }

    bool has_field(const std::string& field_name) const {
        ensure_fields_registered();
        auto& registry = FieldRegistry::instance();
        return registry.get_field(std::type_index(typeid(Derived)), field_name) != nullptr;
    }

    const FieldInfo* get_field_info(const std::string& field_name) const {
        ensure_fields_registered();
        auto& registry = FieldRegistry::instance();
        return registry.get_field(std::type_index(typeid(Derived)), field_name);
    }

    virtual std::vector<std::string> custom_validate() {
        return {};
    }

protected:
    void ensure_fields_registered() const {
        static bool registered = false;
        
        if (!registered) {
            register_fields();
            registered = true;
        }
    }
    
    // Método virtual que devuelve punteros a los campos
    virtual std::vector<void*> get_field_pointers() { return {}; }
    
    // Template helper para registrar un campo (público para que la macro pueda usarlo)
    template<typename T>
    static void register_single_field(Derived* instance, Field<T>* field) {
        size_t offset = reinterpret_cast<char*>(field) - 
                       reinterpret_cast<char*>(instance);
        field->register_in_registry(std::type_index(typeid(Derived)), offset);
    }

private:
    static void register_fields() {
        in_registration = true;
        
        // Crear instancia temporal
        Derived temp_instance;
        
        // Llamar a get_field_pointers para triggerar el registro
        temp_instance.get_field_pointers();
        
        in_registration = false;
    }
};

// Macro mínima para registrar campos
#define REGISTER_FIELDS(...) \
    std::vector<void*> get_field_pointers() override { \
        register_fields_impl(__VA_ARGS__); \
        return {}; \
    } \
    template<typename... Fields> \
    void register_fields_impl(Fields&... fields) { \
        (register_single_field(this, &fields), ...); \
    }

#endif // BASE_MODEL_HPP