<?php

class TestClass {

  /**
   * @var {string}
   */
  private $value;

  public function __construct()
  {
    $this->value = 'test';
  }

  public function set_value($value) {
    $this->value = $value;
  }

}

$test = new TestClass();

