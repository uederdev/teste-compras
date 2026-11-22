package br.com.techagro.compras.controllers;

import br.com.techagro.compras.domain.products.ProductsResponse;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/api/v1/products")
public class ProductController {

    @GetMapping
    public ResponseEntity<List<ProductsResponse>> findAll(){
        return ResponseEntity.ok().body(List.of());
    }
}
