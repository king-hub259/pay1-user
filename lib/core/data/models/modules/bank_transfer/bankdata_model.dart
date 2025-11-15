import '../../../../utils/url_container.dart';
import '../../global/formdata/dynamic_forms_map.dart';

class BankDataModel {
  int? id;
  String? name;
  String? bankCode; // 👈 Added: the actual bank code (e.g., "000013")
  String? fixedCharge;
  String? percentCharge;
  String? formId;
  String? image;
  String? status;
  String? createdAt;
  String? updatedAt;
  DynamicFormsMap? form;

  BankDataModel({
    this.id,
    this.name,
    this.bankCode,
    this.fixedCharge,
    this.percentCharge,
    this.formId,
    this.image,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.form,
  });

  factory BankDataModel.fromJson(Map<String, dynamic> json) => BankDataModel(
    id: json["id"],
    name: json["name"]?.toString(),
    bankCode: json["bank_code"]?.toString() ?? json["code"]?.toString(), // 👈 Add fallback key if API uses "code"
    fixedCharge: json["fixed_charge"]?.toString(),
    percentCharge: json["percent_charge"]?.toString(),
    formId: json["form_id"]?.toString(),
    image: json["image"]?.toString(),
    status: json["status"]?.toString(),
    createdAt: json["created_at"]?.toString(),
    updatedAt: json["updated_at"]?.toString(),
    form: json["form"] == null ? null : DynamicFormsMap.fromJson(json["form"]),
  );

  Map<String, dynamic> toJson() => {
    "id": id,
    "name": name,
    "bank_code": bankCode,
    "fixed_charge": fixedCharge,
    "percent_charge": percentCharge,
    "form_id": formId,
    "image": image,
    "status": status,
    "created_at": createdAt,
    "updated_at": updatedAt,
    "form": form?.toJson(),
  };

  String? getBankImageUrl() {
    if (image == null) {
      return null;
    } else {
      var imageUrl = '${UrlContainer.domainUrl}/assets/images/bank_transfer/$image';
      return imageUrl;
    }
  }
}
