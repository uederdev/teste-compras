package br.com.techagro.compras.domain.products;

import java.math.BigDecimal;

public record ProductCreateRequest(
        String nome,
        String descricao,
        String sku,
        BigDecimal preco) {
}
