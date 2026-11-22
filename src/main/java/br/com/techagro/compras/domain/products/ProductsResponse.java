package br.com.techagro.compras.domain.products;

import java.math.BigDecimal;
import java.util.UUID;

public record ProductsResponse(
        UUID id,
        String nome,
        String descricao,
        String sku,
        BigDecimal preco
        ) {
}