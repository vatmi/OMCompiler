/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2014, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR
 * THIS OSMC PUBLIC LICENSE (OSMC-PL) VERSION 1.2.
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES
 * RECIPIENT'S ACCEPTANCE OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3,
 * ACCORDING TO RECIPIENTS CHOICE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or
 * http://www.openmodelica.org, and in the OpenModelica distribution.
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 */

encapsulated package NFComponent

import DAE;
import Binding = NFBinding;
import NFClass.Class;
import Dimension = NFDimension;
import NFInstNode.InstNode;
import NFMod.Modifier;
import SCode.Element;
import SCode;
import Type = NFType;
import Expression = NFExpression;

protected
import NFInstUtil;
import List;

public
constant Component.Attributes CONST_ATTR =
  Component.Attributes.ATTRIBUTES(
     DAE.NON_CONNECTOR(),
     DAE.NON_PARALLEL(),
     DAE.VARIABLE(),
     DAE.BIDIR(),
     DAE.NOT_INNER_OUTER(),
     DAE.PUBLIC());

constant Component.Attributes INPUT_ATTR =
  Component.Attributes.ATTRIBUTES(
     DAE.NON_CONNECTOR(),
     DAE.NON_PARALLEL(),
     DAE.VARIABLE(),
     DAE.INPUT(),
     DAE.NOT_INNER_OUTER(),
     DAE.PUBLIC());

constant Component.Attributes OUTPUT_ATTR =
  Component.Attributes.ATTRIBUTES(
     DAE.NON_CONNECTOR(),
     DAE.NON_PARALLEL(),
     DAE.VARIABLE(),
     DAE.OUTPUT(),
     DAE.NOT_INNER_OUTER(),
     DAE.PUBLIC());

uniontype Component
  uniontype Attributes
    record ATTRIBUTES
      // adrpo: keep the order in DAE.ATTR
      DAE.ConnectorType connectorType;
      DAE.VarParallelism parallelism;
      DAE.VarKind variability;
      DAE.VarDirection direction;
      DAE.VarInnerOuter innerOuter;
      DAE.VarVisibility visibility;
    end ATTRIBUTES;

    record DEFAULT end DEFAULT;
  end Attributes;

  record COMPONENT_DEF
    SCode.Element definition;
    Modifier modifier;
  end COMPONENT_DEF;

  record UNTYPED_COMPONENT
    InstNode classInst;
    array<Dimension> dimensions;
    Binding binding;
    Component.Attributes attributes;
    Boolean isRedeclare;
    SourceInfo info;
  end UNTYPED_COMPONENT;

  record TYPED_COMPONENT
    InstNode classInst;
    Type ty;
    Binding binding;
    Component.Attributes attributes;
    SourceInfo info;
  end TYPED_COMPONENT;

  record ITERATOR
    Type ty;
    Binding binding;
  end ITERATOR;

  record ENUM_LITERAL
    Expression literal;
  end ENUM_LITERAL;

  function new
    input SCode.Element definition;
    output Component component;
  algorithm
    component := COMPONENT_DEF(definition, Modifier.NOMOD());
  end new;

  function newEnum
    input Type enumType;
    input String literalName;
    input Integer literalIndex;
    output Component component;
  algorithm
    component := ENUM_LITERAL(Expression.ENUM_LITERAL(enumType, literalName, literalIndex));
  end newEnum;

  function definition
    input Component component;
    output SCode.Element definition;
  algorithm
    COMPONENT_DEF(definition = definition) := component;
  end definition;

  function info
    "This function shouldn't be used! Use InstNode.info instead, so that e.g.
     enumeration literals can be handled correctly."
    input Component component;
    output SourceInfo info;
  algorithm
    info := match component
      case COMPONENT_DEF() then SCode.elementInfo(component.definition);
      case UNTYPED_COMPONENT() then component.info;
      case TYPED_COMPONENT() then component.info;
    end match;
  end info;

  function classInstance
    input Component component;
    output InstNode classInst;
  algorithm
    classInst := match component
      case UNTYPED_COMPONENT() then component.classInst;
      case TYPED_COMPONENT() then component.classInst;
    end match;
  end classInstance;

  function setClassInstance
    input InstNode classInst;
    input output Component component;
  algorithm
    () := match component
      case UNTYPED_COMPONENT()
        algorithm
          component.classInst := classInst;
        then
          ();

      case TYPED_COMPONENT()
        algorithm
          component.classInst := classInst;
        then
          ();

    end match;
  end setClassInstance;

  function getModifier
    input Component component;
    output Modifier modifier;
  algorithm
    modifier := match component
      case COMPONENT_DEF() then component.modifier;
      else Modifier.NOMOD();
    end match;
  end getModifier;

  function setModifier
    input Modifier modifier;
    input output Component component;
  algorithm
    () := match component
      case COMPONENT_DEF()
        algorithm
          component.modifier := modifier;
        then
          ();
    end match;
  end setModifier;

  function mergeModifier
    input Modifier modifier;
    input output Component component;
  algorithm
    () := match component
      case COMPONENT_DEF()
        algorithm
          component.modifier := Modifier.merge(modifier, component.modifier);
        then
          ();
    end match;
  end mergeModifier;

  function getType
    input Component component;
    output Type ty;
  algorithm
    ty := match component
      case TYPED_COMPONENT() then component.ty;
      case UNTYPED_COMPONENT() then Class.getType(InstNode.getClass(component.classInst));
      case ITERATOR() then component.ty;
      else Type.UNKNOWN();
    end match;
  end getType;

  function setType
    input Type ty;
    input output Component component;
  algorithm
    component := match component
      case UNTYPED_COMPONENT()
        then TYPED_COMPONENT(component.classInst, ty, component.binding, component.attributes, component.info);

      case TYPED_COMPONENT()
        algorithm
          component.ty := ty;
        then
          component;

      case ITERATOR()
        algorithm
          component.ty := ty;
        then
          component;

    end match;
  end setType;

  function isTyped
    input Component component;
    output Boolean isTyped;
  algorithm
    isTyped := match component
      case TYPED_COMPONENT() then true;
      case ITERATOR(ty = Type.UNKNOWN()) then false;
      case ITERATOR() then true;
      else false;
    end match;
  end isTyped;

  function unliftType
    input output Component component;
  algorithm
    () := match component
      local
        Type ty;

      case TYPED_COMPONENT(ty = Type.ARRAY(elementType = ty))
        algorithm
          component.ty := ty;
        then
          ();

      case ITERATOR(ty = Type.ARRAY(elementType = ty))
        algorithm
          component.ty := ty;
        then
          ();

      else ();
    end match;
  end unliftType;

  function getAttributes
    input Component component;
    output Component.Attributes attr;
  algorithm
    attr := match component
      case UNTYPED_COMPONENT() then component.attributes;
      case TYPED_COMPONENT() then component.attributes;
    end match;
  end getAttributes;

  function getBinding
    input Component component;
    output Binding b;
  algorithm
    b := match component
      case UNTYPED_COMPONENT() then component.binding;
      case TYPED_COMPONENT() then component.binding;
      case ITERATOR() then component.binding;
    end match;
  end getBinding;

  function hasBinding
    input Component component;
    output Boolean b;
  algorithm
    b := match getBinding(component)
      case UNBOUND() then false;
      else true;
    end match;
  end hasBinding;

  function direction
    input Component component;
    output DAE.VarDirection direction;
  algorithm
    direction := match component
      case TYPED_COMPONENT(attributes = Attributes.ATTRIBUTES(direction = direction)) then direction;
      case UNTYPED_COMPONENT(attributes = Attributes.ATTRIBUTES(direction = direction)) then direction;
      else DAE.VarDirection.BIDIR();
    end match;
  end direction;

  function isInput
    input Component component;
    output Boolean isInput;
  algorithm
    isInput := match direction(component)
      case DAE.VarDirection.INPUT() then true;
      else false;
    end match;
  end isInput;

  function isOutput
    input Component component;
    output Boolean isOutput;
  algorithm
    isOutput := match direction(component)
      case DAE.VarDirection.OUTPUT() then true;
      else false;
    end match;
  end isOutput;

  function variability
    input Component component;
    output DAE.VarKind variability;
  algorithm
    variability := match component
      case TYPED_COMPONENT(attributes = Attributes.ATTRIBUTES(variability = variability)) then variability;
      case TYPED_COMPONENT(attributes = Attributes.DEFAULT()) then DAE.VarKind.VARIABLE();
      case UNTYPED_COMPONENT(attributes = Attributes.ATTRIBUTES(variability = variability)) then variability;
      case UNTYPED_COMPONENT(attributes = Attributes.DEFAULT()) then DAE.VarKind.VARIABLE();
      case ITERATOR() then DAE.VarKind.CONST();
      else fail();
    end match;
  end variability;

  function isConst
    input Component component;
    output Boolean isConst;
  algorithm
    isConst := match variability(component)
      case DAE.VarKind.CONST() then true;
      else false;
    end match;
  end isConst;

  function visibility
    input Component component;
    output DAE.VarVisibility visibility;
  algorithm
    visibility := match component
      case COMPONENT_DEF() then
        if SCode.isElementProtected(component.definition) then
          DAE.VarVisibility.PROTECTED() else DAE.VarVisibility.PUBLIC();
      case UNTYPED_COMPONENT(attributes = Attributes.ATTRIBUTES(visibility = visibility)) then visibility;
      case TYPED_COMPONENT(attributes = Attributes.ATTRIBUTES(visibility = visibility)) then visibility;
      // Iterators and enumeration literals can't be accessed in a way where visibility matters.
      else DAE.VarVisibility.PUBLIC();
    end match;
  end visibility;

  function isPublic
    input Component component;
    output Boolean isInput;
  algorithm
    isInput := match visibility(component)
      case DAE.VarVisibility.PUBLIC() then true;
      else false;
    end match;
  end isPublic;

  function isIdentical
    input Component comp1;
    input Component comp2;
    output Boolean identical = false;
  algorithm
    identical := match (comp1, comp2)
      case (UNTYPED_COMPONENT(), UNTYPED_COMPONENT())
        algorithm
          if not Class.isIdentical(InstNode.getClass(comp1.classInst),
                                   InstNode.getClass(comp2.classInst)) then
            return;
          end if;

          if not Binding.isEqual(comp1.binding, comp2.binding) then
            return;
          end if;
        then
          true;

      else true;
    end match;
  end isIdentical;

  function toString
    input String name;
    input Component component;
    output String str;
  algorithm
    str := match component
      local
        SCode.Element def;

      case COMPONENT_DEF(definition = def as SCode.Element.COMPONENT())
        then Dump.unparseTypeSpec(def.typeSpec) + " " + name +
             Modifier.toString(component.modifier);

      case UNTYPED_COMPONENT()
        then InstNode.name(component.classInst) + " " + name +
             List.toString(arrayList(component.dimensions), Dimension.toString, "", "[", ", ", "]", false) +
             Binding.toString(component.binding, " = ");

    end match;
  end toString;

  function isRedeclare
    input Component component;
    output Boolean isRedeclare;
  algorithm
    isRedeclare := match component
      case COMPONENT_DEF() then SCode.isElementRedeclare(component.definition);
      case UNTYPED_COMPONENT() then component.isRedeclare;
      else false;
    end match;
  end isRedeclare;

end Component;

annotation(__OpenModelica_Interface="frontend");
end NFComponent;
