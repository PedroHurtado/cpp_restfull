#ifndef FIELD_VALIDATOR_HPP
#define FIELD_VALIDATOR_HPP

#include <string>
#include <vector>
#include <functional>
#include <optional>
#include <regex>
#include <sstream>
#include <type_traits>

class IFieldValidator
{
public:
    virtual ~IFieldValidator() = default;

    // Obtener nombre del campo
    virtual std::string get_field_name() const = 0;

    // Obtener descripción
    virtual std::string get_description() const = 0;

protected:
    IFieldValidator() = default;
};
// Opciones de validación para un campo
template <typename T>
struct FieldOptions
{
    bool required = false;
    std::optional<size_t> min_length;                // Para strings
    std::optional<size_t> max_length;                // Para strings
    std::optional<T> min_value;                      // Para números
    std::optional<T> max_value;                      // Para números
    std::optional<std::string> pattern;              // Regex para strings
    std::optional<T> default_val;                    // Valor por defecto
    std::vector<T> allowed_values;                   // Enum/whitelist
    std::function<bool(const T &)> custom_validator; // Validador custom
    std::string custom_error_msg;                    // Mensaje de error custom
    std::string description;                         // Descripción del campo
};

// Validador de campo tipado - Responsabilidad única: validar valores
template <typename T>
class FieldValidator : public IFieldValidator
{
public:
    using Options = FieldOptions<T>;

    FieldValidator(const std::string &field_name, Options opts)
        : field_name_(field_name), options_(opts) {}

    // Validar un valor según las reglas
    std::pair<bool, std::string> validate(const T &value) const
    {
        // Validaciones específicas por tipo usando if constexpr (C++17)
        if constexpr (std::is_same_v<T, std::string>)
        {
            return validate_string(value);
        }
        else if constexpr (std::is_arithmetic_v<T>)
        {
            return validate_numeric(value);
        }
        else
        {
            // Para otros tipos, solo validación custom
            return validate_custom(value);
        }
    }

    // Validar si el campo es requerido
    bool is_required() const
    {
        return options_.required;
    }

    // Obtener valor por defecto si existe
    std::optional<T> get_default() const
    {
        return options_.default_val;
    }

    // Obtener nombre del campo
    std::string get_field_name() const
    {
        return field_name_;
    }

    // Obtener descripción
    std::string get_description() const
    {
        return options_.description;
    }

private:
    // Validaciones específicas para strings
    std::pair<bool, std::string> validate_string(const std::string &value) const
    {
        // Longitud mínima
        if (options_.min_length && value.length() < *options_.min_length)
        {
            return {false, "Field '" + field_name_ + "' must have at least " +
                               std::to_string(*options_.min_length) + " characters"};
        }

        // Longitud máxima
        if (options_.max_length && value.length() > *options_.max_length)
        {
            return {false, "Field '" + field_name_ + "' must have at most " +
                               std::to_string(*options_.max_length) + " characters"};
        }

        // Patrón regex
        if (options_.pattern)
        {
            try
            {
                std::regex regex_pattern(*options_.pattern);
                if (!std::regex_match(value, regex_pattern))
                {
                    return {false, "Field '" + field_name_ + "' does not match required pattern"};
                }
            }
            catch (const std::regex_error &e)
            {
                return {false, "Field '" + field_name_ + "' has invalid regex pattern"};
            }
        }

        // Valores permitidos y custom
        return validate_allowed_and_custom(value);
    }

    // Validaciones específicas para números
    std::pair<bool, std::string> validate_numeric(const T &value) const
    {
        // Valor mínimo
        if (options_.min_value && value < *options_.min_value)
        {
            std::ostringstream oss;
            oss << "Field '" << field_name_ << "' must be at least " << *options_.min_value;
            return {false, oss.str()};
        }

        // Valor máximo
        if (options_.max_value && value > *options_.max_value)
        {
            std::ostringstream oss;
            oss << "Field '" << field_name_ << "' must be at most " << *options_.max_value;
            return {false, oss.str()};
        }

        // Valores permitidos y custom
        return validate_allowed_and_custom(value);
    }

    // Validar valores permitidos (enum/whitelist)
    std::pair<bool, std::string> validate_allowed_and_custom(const T &value) const
    {
        // Valores permitidos
        if (!options_.allowed_values.empty())
        {
            bool found = false;
            for (const auto &allowed : options_.allowed_values)
            {
                if (value == allowed)
                {
                    found = true;
                    break;
                }
            }
            if (!found)
            {
                return {false, "Field '" + field_name_ + "' must be one of the allowed values"};
            }
        }

        // Validador custom
        return validate_custom(value);
    }

    // Validador personalizado
    std::pair<bool, std::string> validate_custom(const T &value) const
    {
        if (options_.custom_validator && !options_.custom_validator(value))
        {
            std::string error_msg = options_.custom_error_msg.empty()
                                        ? "Field '" + field_name_ + "' failed custom validation"
                                        : options_.custom_error_msg;
            return {false, error_msg};
        }

        return {true, ""}; // Todo OK
    }

    std::string field_name_;
    Options options_;
};

#endif // FIELD_VALIDATOR_HPP