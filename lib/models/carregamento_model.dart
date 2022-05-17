class CarregamentoModel {
  String? codigoCliente;
  String? nomeFantasia;
  String? razaoSocial;
  String? endereco;
  String? complemento;
  String? bairro;
  String? cep;
  String? cidade;
  String? uf;

  CarregamentoModel(
      {this.codigoCliente,
        this.nomeFantasia,
        this.razaoSocial,
        this.endereco,
        this.complemento,
        this.bairro,
        this.cep,
        this.cidade,
        this.uf});

  CarregamentoModel.fromJson(Map<String, dynamic> json) {
    codigoCliente = json['codigo_cliente'];
    nomeFantasia = json['nome_fantasia'];
    razaoSocial = json['razao_social'];
    endereco = json['endereco'];
    complemento = json['complemento'];
    bairro = json['bairro'];
    cep = json['cep'];
    cidade = json['cidade'];
    uf = json['uf'];
  }
}
