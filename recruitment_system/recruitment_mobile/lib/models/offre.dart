class Offre {
  final int id;
  final String titre;
  final String description;
  final String competences;
  final String enterprise;
  final String type;

  Offre({
    required this.id,
    required this.titre,
    required this.description,
    required this.competences,
    required this.enterprise,
    required this.type,
  });

  factory Offre.fromJson(Map<String, dynamic> json) {
    return Offre(
      id: json['id'] ?? 0,
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      competences: json['competences_requises'] ?? '',
      enterprise: json['enterprise_name'] ?? 'Entreprise',
      type: json['type_contrat'] ?? 'CDI',
    );
  }
}