#ifndef FIELD_REGISTRY_HPP
#define FIELD_REGISTRY_HPP

#include "field_validator.hpp"
#include <map>
#include <string>
#include <memory>
#include <typeindex>
#include <vector>

// Información de un campo registrado
struct FieldInfo {
    std::shared_ptr<IFieldValidator> validator;  // El validador
    size_t offset;                                // Offset del campo en la clase (mutable)
    std::type_index value_type;                   // Tipo del valor (std::string, int, etc.)
    std::function<std::pair<bool, std::string>(void*)> validate_func;  // Función de validación
    
    FieldInfo(std::shared_ptr<IFieldValidator> val, size_t off, std::type_index type)
        : validator(val), offset(off), value_type(type), validate_func(nullptr) {}
        
    FieldInfo(std::shared_ptr<IFieldValidator> val, size_t off, std::type_index type,
              std::function<std::pair<bool, std::string>(void*)> validate_fn)
        : validator(val), offset(off), value_type(type), validate_func(validate_fn) {}
};

// Singleton: Registro global de campos por tipo de modelo
class FieldRegistry {
public:
    // Obtener instancia única
    static FieldRegistry& instance() {
        static FieldRegistry registry;
        return registry;
    }

    // Registrar un campo para un tipo de modelo específico
    void register_field(std::type_index model_type,
                       const std::string& field_name,
                       std::shared_ptr<IFieldValidator> validator,
                       size_t offset,
                       std::type_index value_type,
                       std::function<std::pair<bool, std::string>(void*)> validate_func = nullptr) {
        fields_[model_type].emplace_back(validator, offset, value_type, validate_func);
        field_names_[model_type][field_name] = fields_[model_type].size() - 1;
    }

    // Obtener todos los campos de un tipo de modelo
    const std::vector<FieldInfo>& get_fields(std::type_index model_type) const {
        static std::vector<FieldInfo> empty;
        auto it = fields_.find(model_type);
        return it != fields_.end() ? it->second : empty;
    }

    // Obtener un campo específico por nombre
    const FieldInfo* get_field(std::type_index model_type, const std::string& field_name) const {
        auto model_it = field_names_.find(model_type);
        if (model_it == field_names_.end()) {
            return nullptr;
        }

        auto field_it = model_it->second.find(field_name);
        if (field_it == model_it->second.end()) {
            return nullptr;
        }

        size_t index = field_it->second;
        return &fields_.at(model_type)[index];
    }

    // Verificar si un modelo tiene campos registrados
    bool has_fields(std::type_index model_type) const {
        return fields_.find(model_type) != fields_.end();
    }

    // Obtener cantidad de campos registrados para un modelo
    size_t field_count(std::type_index model_type) const {
        auto it = fields_.find(model_type);
        return it != fields_.end() ? it->second.size() : 0;
    }

    // Actualizar el offset de un campo específico
    void update_field_offset(std::type_index model_type, const std::string& field_name, size_t new_offset) {
        auto model_it = field_names_.find(model_type);
        if (model_it == field_names_.end()) {
            return;
        }

        auto field_it = model_it->second.find(field_name);
        if (field_it == model_it->second.end()) {
            return;
        }

        size_t index = field_it->second;
        fields_[model_type][index].offset = new_offset;
    }

    // Limpiar todos los registros (útil para testing)
    void clear() {
        fields_.clear();
        field_names_.clear();
    }

    // Limpiar registros de un modelo específico
    void clear_model(std::type_index model_type) {
        fields_.erase(model_type);
        field_names_.erase(model_type);
    }

private:
    // Constructor privado (Singleton)
    FieldRegistry() = default;

    // Evitar copia
    FieldRegistry(const FieldRegistry&) = delete;
    FieldRegistry& operator=(const FieldRegistry&) = delete;

    // Almacenamiento: type_index -> vector de FieldInfo
    std::map<std::type_index, std::vector<FieldInfo>> fields_;

    // Índice rápido: type_index -> (field_name -> index en vector)
    std::map<std::type_index, std::map<std::string, size_t>> field_names_;
};

#endif // FIELD_REGISTRY_HPP