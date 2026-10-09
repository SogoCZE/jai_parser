Data :: struct {
	id: int;
}

write :: (data: Data) {}

main :: () {
	test: Data = {};
	test := {};
	test = {};
	write(data={id=1});
	write(data={1});
	write({1});

	return {{}};
}

Drak :: () {

}

Item :: struct { name: string; }
Person :: struct { items: [4]Item; position: struct { x: int; }; }

ORIGIN : Data : {1};

designators :: (index: int) {
	p: Person = {items[0].name="Test item", position.x = 3};
	q := Person.{items[index].name = "x"};
	d := ifx index then Data.{1} else {2};
	e := #ifx true { Data.{3}; } else { Data.{4}; };
}
