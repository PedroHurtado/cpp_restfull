#include <iostream>
#include <vector>
#include <string>
#include <algorithm>
#include <ranges>

int main() {
    std::cout << "¡Hola desde el dev container de C++!" << std::endl;
    
    // Ejemplo usando características de C++20
    std::vector<int> numeros = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10};
    
    // Usar ranges (C++20)
    auto pares = numeros 
        | std::views::filter([](int n) { return n % 2 == 0; });
    
    std::cout << "Números pares: ";
    for (int numero : pares) {
        std::cout << numero << " ";
    }
    std::cout << std::endl;
    
    return 0;
}