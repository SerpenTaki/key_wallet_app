import 'package:flutter_test/flutter_test.dart';
import 'package:key_wallet_app/services/validators.dart';

void main(){
  final validator = Validator();

  group("Required Validator", (){
    test("Required ok", (){
      String? a = validator.requiredValidator("Campo obbligatorio");
      expect(a, isNull);
    });

    test("Required fail", (){
      String? a = validator.requiredValidator(null);
      expect(a, "Questo campo è obbligatorio");
    });
  });

  group("Email Validator", (){
    test("Email OK", (){
      String? a = validator.emailValidator("john.c.calhoun@examplepetstore.com");
      expect(a, isNull);
    });
    test("Email not valid", (){
      String? a = validator.emailValidator("ciao");
      expect(a, 'Inserisci un\'email valida');
    });
    test("Not Mail", (){
      String? a = validator.emailValidator(null);
      expect(a, 'Inserisci un indirizzo email');
    });
  });


  group("Password Validator", (){
    test("Password Ok",(){
      String? a = validator.passwordValidator("password");
      expect(a, isNull);
    });
    test("Password not valid", (){
      String? a = validator.passwordValidator("ciao");
      expect(a, 'Password non valida');
    });
    test("Not Password", (){
      String? a = validator.passwordValidator(null);
      expect(a, 'Inserisci una password');
    });
  });
}